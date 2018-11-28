extends Node

# Linear interpolate float values
func f_linear_interpolate(from, to, delta):
    # TODO: Check types
    delta = clamp(delta, 0, 1)
    var diff = to - from
    return from + diff * delta
