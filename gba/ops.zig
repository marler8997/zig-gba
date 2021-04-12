pub fn genericMemset(comptime T: type, destination: [*]volatile u8, value: T, count: usize) void {
    @setRuntimeSafety(false);
    const valueBytes = @ptrCast([*]const u8, &value);
    var index: usize = 0;
    while (index != count) : (index += 1) {
        comptime var expandIndex = 0;
        inline while (expandIndex < @sizeOf(T)) : (expandIndex += 1) {
            destination[(index * @sizeOf(T)) + expandIndex] = valueBytes[expandIndex];
        }
    }
}

pub fn alignedMemset(comptime T: type, destination: [*]align(@alignOf(T)) volatile u8, value: T, count: usize) void {
    @setRuntimeSafety(false);
    const alignedDestination = @ptrCast([*]volatile T, destination);
    var index: usize = 0;
    while (index != count) : (index += 1) {
        alignedDestination[index] = value;
    }
}

pub fn memset32(destination: anytype, value: u32, count: usize) void {
    if ((@ptrToInt(@ptrCast(*u8, destination)) % 4) == 0) {
        alignedMemset(u32, @ptrCast([*]align(4) volatile u8, @alignCast(4, destination)), value, count);
    } else {
        genericMemset(u32, @ptrCast([*]volatile u8, destination), value, count);
    }
}

pub fn memcpy32(noalias destination: anytype, noalias source: anytype, count: usize) void {
    if (count < 4) {
        genericMemcpy(@ptrCast([*]u8, destination), @ptrCast([*]const u8, source), count);
    } else {
        if ((@ptrToInt(@ptrCast(*u8, destination)) % 4) == 0 and (@ptrToInt(@ptrCast(*const u8, source)) % 4) == 0) {
            alignedMemcpy(u32, @ptrCast([*]align(4) volatile u8, @alignCast(4, destination)), @ptrCast([*]align(4) const u8, @alignCast(4, source)), count);
        } else if ((@ptrToInt(@ptrCast(*u8, destination)) % 2) == 0 and (@ptrToInt(@ptrCast(*const u8, source)) % 2) == 0) {
            alignedMemcpy(u16, @ptrCast([*]align(2) volatile u8, @alignCast(2, destination)), @ptrCast([*]align(2) const u8, @alignCast(2, source)), count);
        } else {
            genericMemcpy(@ptrCast([*]volatile u8, destination), @ptrCast([*]const u8, source), count);
        }
    }
}

pub fn memcpy16(noalias destination: anytype, noalias source: anytype, count: usize) void {
    if (count < 2) {
        genericMemcpy(@ptrCast([*]u8, destination), @ptrCast([*]const u8, source), count);
    } else {
        if ((@ptrToInt(@ptrCast(*u8, destination)) % 2) == 0 and (@ptrToInt(@ptrCast(*const u8, source)) % 2) == 0) {
            alignedMemcpy(u16, @ptrCast([*]align(2) volatile u8, @alignCast(2, destination)), @ptrCast([*]align(2) const u8, @alignCast(2, source)), count);
        } else {
            genericMemcpy(@ptrCast([*]volatile u8, destination), @ptrCast([*]const u8, source), count);
        }
    }
}

pub fn alignedMemcpy(comptime T: type, noalias destination: [*]align(@alignOf(T)) volatile u8, noalias source: [*]align(@alignOf(T)) const u8, count: usize) void {
    @setRuntimeSafety(false);
    const alignSize = count / @sizeOf(T);
    const remainderSize = count % @sizeOf(T);

    const alignDestination = @ptrCast([*]volatile T, destination);
    const alignSource = @ptrCast([*]const T, source);

    var index: usize = 0;
    while (index != alignSize) : (index += 1) {
        alignDestination[index] = alignSource[index];
    }

    index = count - remainderSize;
    while (index != count) : (index += 1) {
        destination[index] = source[index];
    }
}

pub fn genericMemcpy(noalias destination: [*]volatile u8, noalias source: [*]const u8, count: usize) void {
    @setRuntimeSafety(false);
    var index: usize = 0;
    while (index != count) : (index += 1) {
        destination[index] = source[index];
    }
}
