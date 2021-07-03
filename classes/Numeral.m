function a = Numeral(b)
    if Options.usingGpuComputation
        a = gpuArray(b);
    else
        a = gather(b);
    end
end