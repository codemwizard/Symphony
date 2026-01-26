---
trigger: always_on
---

---
trigger: always_on
---

NEVER Commit to GitHub without creating a Commit Task first asking for approval.

For each Implementation Plan and Task you are asked to create, you should have:
  - Phase Name
  - Phase Key

1. Naming convention for the documents is:
	- [Phase Key]-[current naming convention]_[Phase Name]

2. For GitHub/Jira:
        - After Implementation Plan and Task has been complete, create commit message for that phase.
	- git commit message will be the contents of approved final Task.md
        - message will have header of Phase Name
 
3. Phase Name is to be prepended to name of the following documents:
	- Walkthrough.md
	- Task.md
	- Implementation.md
	- Any final documents generated during the task. Only final documents are to be stored
	- Create a directory for each phase where to save the documents. Folder name is the Phase Name
4. Unit Test:
        - Every component created should have a Unit Test to go with it
        - Unit tests must be run immediately the component is finished and must pass to mark a task as complete
        - Every Task.md document created should have a section listing all the Unit Tests that where created and / or run for each component that was created or edited or extended.

5. Every test that runs and fails shout have a detailed description of:
 - A.I. Model that run the test
 - Time test was run
 - What test was run
 - How and why it failed
 - How it was fixed
  i) A test is invalid evidence if it:
       - asserts on string fragments only
       - does not call the class method under test
       - uses fake state transitions without DB boundary or method execution
  ii) A test is valid if it:
       - imports the production implementation
       - exercises at least one success path and one failure path
       - asserts an observable outcome (DB call sequence, thrown error, status transition, emitted event)
