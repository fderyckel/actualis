# Phase 0 surface prototype briefs

Status: briefs prepared; visual directions, interactive prototypes, and usability validation are
not started.

These briefs deliberately define user outcomes and evidence without selecting a shared SDK or visual
system. Fictional data is mandatory. A prototype is exploratory and must not be presented as an
implemented Actualis product surface.

## Manufacturing: scan-first operator surface

**User and setting:** a gloved operator using a shared rugged tablet near material flow.  
**Outcome:** scan a pallet, understand whether movement is permitted, and complete or recover from
the next governed action with minimal typing.  
**Must expose:** online/offline state, scan receipt, pallet identity, claimed and authoritative
locations, quality state, purpose, permitted next action, idempotent submission state, denial or
conflict recovery, and evidence reference.  
**Must not expose:** planner-only context, unrestricted policy detail, other sites, or a control that
implies Core can override physical safety.

Prototype states: ready to scan, resolving, permitted, quality-held, stale location, queued but not
authorized, committed, duplicate replay, expired, and connectivity recovery.

## Education A: scheduler constraint workbench

**User and setting:** a school scheduler on a large desktop display resolving a teacher absence.  
**Outcome:** compare a small set of alternatives against hard constraints and commitments, select a
response, and see when approval is required.  
**Must expose:** authoritative snapshot version, affected lessons and people counts, hard versus soft
constraints, infeasibility, trade-offs, conflicts, selection status, approval state, and evidence
trail.  
**Must not expose:** unnecessary safeguarding or personal details, hidden automatic commitment, or a
way to approve one's own conflicting selection.

This is intentionally information-dense and comparison-oriented, materially different from the
scan-first manufacturing flow.

## Education B: teacher mobile change acknowledgement

**User and setting:** a teacher on a phone between lessons.  
**Outcome:** understand one timetable change, why it affects them, acknowledge it, or report that it
cannot be executed.  
**Must expose:** changed lesson, effective time, location, minimum explanation, acknowledgement due
time, offline/queued state, and escalation path.  
**Must not expose:** the scheduler's complete candidate set, protected learner information, policy
internals, or ambiguous delivered-versus-seen status.

This is intentionally single-task, mobile, and acknowledgement-oriented rather than a reduced copy
of the scheduler workbench.

## Evaluation protocol

For each prototype, recruit at least three representatives of the named role and record:

1. whether they can state the current authoritative state;
2. whether they can distinguish proposed, approved, committed, delivered, and executed states;
3. whether they choose the intended recovery path for stale, denied, offline, and expired cases;
4. time to first correct action and avoidable steps;
5. fields they need but cannot find, and fields shown without a justified purpose;
6. language that overstates safety, certainty, delivery, or authority; and
7. requested changes to the reality contract or capability envelope.

No SDK decision passes Phase 0 from visual preference alone. Record the tested prototype version,
participants' roles, tasks, findings, and resulting contract changes.
