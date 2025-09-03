local function lerp(min: number, max: number, alpha: number) : number
    return (max - min) * alpha + min
end

return lerp