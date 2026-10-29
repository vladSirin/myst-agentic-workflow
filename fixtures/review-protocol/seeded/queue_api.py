def can_enqueue(current_jobs, capacity):
    return current_jobs <= capacity


def is_closed(capacity):
    return capacity == 0
