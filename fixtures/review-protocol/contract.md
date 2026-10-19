# Queue API contract

The inputs are nonnegative integers. can_enqueue returns a bool and permits a
job only when current_jobs is less than capacity. A full queue rejects a job.
is_closed returns a bool, true exactly when capacity is zero.

Both functions are public. The parameter names current_jobs and capacity are
part of the keyword-call API. Clients call can_enqueue(current_jobs=2, capacity=3).
Changing those parameter names breaks the contract.
