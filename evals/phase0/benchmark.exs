defmodule Actualis.Phase0.Benchmark do
  alias Actualis.Repo
  alias ActualisManufacturing.TestFixture
  alias Ecto.Adapters.SQL.Sandbox

  def run(argv) do
    options = parse_options!(argv)
    worker_count = min(options[:concurrency], options[:commands])

    results =
      options[:commands]
      |> distribute(worker_count)
      |> Task.async_stream(&run_worker/1,
        max_concurrency: worker_count,
        ordered: false,
        timeout: :infinity
      )
      |> Enum.map(fn
        {:ok, result} -> result
        {:exit, reason} -> %{durations_us: [], failures: ["worker_exit:#{inspect(reason)}"]}
      end)

    durations = results |> Enum.flat_map(& &1.durations_us) |> Enum.sort()
    failures = Enum.flat_map(results, & &1.failures)

    report = %{
      "schema_version" => "1.0",
      "measurement" => "in_process_governed_command",
      "environment" => "test_sql_sandbox",
      "commands_requested" => options[:commands],
      "commands_measured" => length(durations),
      "concurrency" => worker_count,
      "latency_ms" => %{
        "p50" => percentile_ms(durations, 0.50),
        "p95" => percentile_ms(durations, 0.95),
        "p99" => percentile_ms(durations, 0.99),
        "max" => percentile_ms(durations, 1.0)
      },
      "failure_count" => length(failures),
      "failures" => Enum.frequencies(failures),
      "limitations" => [
        "no_http_or_network",
        "no_realtime_fanout",
        "sandbox_transactions_roll_back",
        "not_production_shaped"
      ]
    }

    IO.puts(Jason.encode!(report, pretty: true))
    if failures != [], do: System.halt(1)
  end

  defp parse_options!(argv) do
    {options, rest, invalid} =
      OptionParser.parse(argv, strict: [commands: :integer, concurrency: :integer])

    options = Keyword.merge([commands: 50, concurrency: 2], options)

    if rest != [] or invalid != [] or options[:commands] < 1 or options[:concurrency] < 1 do
      raise ArgumentError,
            "usage: benchmark.exs [--commands positive_integer] [--concurrency positive_integer]"
    end

    options
  end

  defp distribute(total, workers) do
    base = div(total, workers)
    remainder = rem(total, workers)

    for worker_index <- 0..(workers - 1) do
      count = base + if(worker_index < remainder, do: 1, else: 0)
      {worker_index, count}
    end
  end

  defp run_worker({worker_index, count}) do
    :ok = Sandbox.checkout(Repo)

    try do
      fixture = TestFixture.create()
      run_commands(fixture, worker_index, count)
    after
      Sandbox.checkin(Repo)
    end
  end

  defp run_commands(fixture, worker_index, count) do
    initial = %{
      source_id: fixture.source.id,
      destination_id: fixture.destination.id,
      version: fixture.pallet.version,
      durations_us: [],
      failures: []
    }

    final =
      Enum.reduce(1..count, initial, fn sequence, state ->
        command =
          TestFixture.command(fixture, %{
            "expected_version" => state.version,
            "idempotency_key" => "phase0-#{worker_index}-#{sequence}",
            "input" => %{
              "source_location_id" => state.source_id,
              "destination_location_id" => state.destination_id,
              "reason" => "Synthetic Phase 0 workload"
            }
          })

        started_at = System.monotonic_time()
        result = ActualisManufacturing.execute(command)

        duration_us =
          started_at
          |> then(&(System.monotonic_time() - &1))
          |> System.convert_time_unit(:native, :microsecond)

        case result do
          {:ok, %{"ok" => true}} ->
            %{
              state
              | source_id: state.destination_id,
                destination_id: state.source_id,
                version: state.version + 1,
                durations_us: [duration_us | state.durations_us]
            }

          {:ok, %{"error" => %{"code" => code}}} ->
            %{state | failures: [code | state.failures]}

          {:error, %{"code" => code}} ->
            %{state | failures: [code | state.failures]}
        end
      end)

    %{durations_us: final.durations_us, failures: final.failures}
  end

  defp percentile_ms([], _percentile), do: nil

  defp percentile_ms(sorted_microseconds, percentile) do
    rank = max(ceil(percentile * length(sorted_microseconds)) - 1, 0)
    sorted_microseconds |> Enum.at(rank) |> Kernel./(1000) |> Float.round(3)
  end
end

Actualis.Phase0.Benchmark.run(System.argv())
