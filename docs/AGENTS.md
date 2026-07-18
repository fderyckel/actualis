# Documentation instructions for agents

These instructions apply to every file under `docs/`.

1. Read `docs/process/documentation-workflow.md` and `docs/doc-map.yaml` before creating or changing documentation.
2. Keep the two documentation tracks separate:
   - `docs/technical/` is optimized for coding agents and technical maintainers, but must remain plain, precise, and human-readable.
   - `docs/user/` is written for people operating or administering Actualis. Do not require code knowledge.
3. Generate documentation from current evidence: implementation, tests, migrations, public contracts, and a working UI. Never use an older document as the sole source for a claim.
4. Label behavior accurately as `implemented`, `partial`, `planned`, `deprecated`, or `not applicable`. Do not describe planned behavior as available.
5. Run three distinct passes for material changes:
   - generate the draft from evidence;
   - verify every behavioral claim against evidence;
   - curate for clarity, navigation, terminology, and audience fit.
6. Update `docs/doc-map.yaml` when a kernel area, source path, documentation page, or user-impact decision changes.
7. Add screenshots when they materially help a user identify a surface, perform a step, confirm success, or recover from an error. Follow `docs/assets/screenshots/README.md`.
8. Never fabricate product screenshots or UI labels. If the surface is not implemented, describe the documentation gap and leave no broken placeholder image.
9. Keep secrets, real personal data, production identifiers, and uncontrolled timestamps out of examples and screenshots.
10. Do not edit files under `sources/`.

Documentation is complete only when the checklist and quality gates in the workflow pass.

