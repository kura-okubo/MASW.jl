module MASW

using FFTW, Plots

export masw

"""
    masw(U::AbstractArray, x::AbstractArray, t::AbstractArray, ct::AbstractArray;
               plotfreqlimits::Tuple=(),
               plotwaterlevel::Real=0.0,
               figdir::String="",
               figname::String="")

Return dispersion curve inferred from Multichannel Analysis of Surface Waves (MASW)

# Arguments
- `U::AbstractArray`: 2D Array for seismci traces: size(U)=(T:length of timeseries, N:number of traces)
- `x::AbstractArray`: Vector for offsets (distance between source and receiver)
- `t::AbstractArray`: Vector for timeseries (ex. 0:1/fs:Tmax)
- `ct::AbstractArray`: Vector for scanning velocity of interest.
- `plotfreqlimits::Tuple=()`: Tuple for minfreq and maxfreq of plotting (ex. (0.0, 10.0))
- `plotwaterlevel::Real=0.0`: Dispersion Image waterlevel expressed as a percent for display purposes.
- `figdir::String=""`: Figure directory name if you want to plot the result figure.
- `figname::String=""`: figname if you want to plot the result figure (please include extention.).

# Usage

`(f, ct, Udisp, DispersionCurve) = masw(U, x, t, ct, plotfreqlimits, plotwaterlevel, figdir, figname)`

# Output

- `f`: Vector for frequency associated with dispersion image.
- `ct`: Vector for scanning velocity associated with dispersion image.
- `Udisp`: Normalized 2D array for dispersion image.
- `DispersionCurve`: DispersionCurve including frequency and automatically picked phase velocity.

# Reference
- Park, C.B., Miller, R.D. and Xia, J. (2001) Offset and resolution of dispersion curve in multichannel analysis of surface waves (MASW). doi:10.4133/1.2922953

Julia version written by kura-okubo (https://github.com/kura-okubo)

This is the translation in Julia based on matlab script written by John Schuh.

Matlab script: Copyright (c) 2018, John Schuh
All rights reserved.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

- John Schuh (2020). MASW Dispersion Curve (https://www.mathworks.com/matlabcentral/fileexchange/65138-masw-dispersion-curve), MATLAB Central File Exchange. Retrieved January 14, 2020.
"""
function masw(U::AbstractArray, x::AbstractArray, t::AbstractArray, ct::AbstractArray;
                plotfreqlimits::Tuple=(),
                plotwaterlevel::Real=0.0,
                figdir::String="",
                figname::String="")

    # precheck of array size
    if size(U) != (length(t), length(x))
        error("size of U is not correct. Please check that size(U) == (length(t), length(x))")
    end

    datanorm = U./maximum(U)

    L=length(t); # number os samples
    T=maximum(t); # max time
    if mod(L,2) == 0
        f = (1/T)*(0:L/2-1); # n is even
    else
        f = (1/T)*(0:(L-1)/2); # n is odd
    end

    Ufft=FFTW.rfft(U, 1) # fft is performed on each column (the time vector)
    w=f*2*pi; # convert the freq vector to rads/sec

    ## 2. Normalize the spectrum
    Rnorm=Ufft./abs.(Ufft); # Normalize the spectrum

    ## 3. Perfrom the summation over N in the frequency domain
    AsSum = zeros(length(w),length(ct))
    @simd for ii=1:length(w) # send in frequencies one at a time
        As=zeros(Complex, length(x),length(ct)); #initialize As or overwite the previous As
        for n=1:length(x) # send in a positon (x) one at a time
            # Iterate As over position
            As[n,:]=exp.(1im*w[ii].*(x[n]./ct)).*Rnorm[ii,n]
        end
         AsSum[ii,:]=abs.(sum(As, dims=1));
    end
    AsSum=AsSum'; # transpose the matrix so velocity is on vertical and freq is on horizontal
    normed=AsSum./maximum(AsSum, dims=1);# normalize the dispersion image so max column values=1

    ############ curve autopicking ###################
    # This section will auto pick the dispersion curve based on the peak
    # value in each column. This will need updating when
    # higher modes are introduced
    remaindat=deepcopy(normed)
    remaindat[remaindat .< 1] .= 0
    ind=findall(x -> x==1, remaindat)
    row = []; col = []
    for i = 1:length(ind)
        push!(row, ind[i][1]); push!(col, ind[i][2])
    end

    autovel=ct[row]; # autopicked velocity indices that contain the peak value
    autofreq=f[col]; # autopicked frequency indices that contain the peak value
    # get rid of all the extra picks at zero frequency
    nz=length(autofreq)-count(x -> x != 0, autofreq); # determine the number of repeated picks at zero
    autofreq=autofreq[nz:end]; # remove the repeated zero picks
    autovel=autovel[nz:end]; # remove the repeated zero picks
    DispersionVelocity=autovel; # need to get the rlowess working again, I no longer have access to the toolbox that allows it
    normed[normed .< plotwaterlevel/100] .= NaN; # throw out data less than plotwaterlevel
    ################ end autopicking ######################

    DispersionCurve=[f, DispersionVelocity]; # this only has meaning if the curve was picked using 'manual' or 'auto'

    if !isempty(figdir)

        if Plots.backend() != Plots.PyPlotBackend()
            @warn ("MASW.jl plotting is available only with pyplot backend. Please type
                    `using Plots;Plots.pyplot()` before call this function. Return result
                     without plotting figure.")
            return (f, ct, normed, DispersionCurve)
        end

        # plot input traces
        l = Plots.@layout [a b]
        p1 = Plots.contourf(x, t, U, levels=200,  yflip = true, xlabel="Distance", ylabel="Time",
                            linewidth=0.0, c=:balance,  title="Traces")
        # Plot the dispersion results
        p2 = Plots.contourf(f,ct,normed, levels=200, xlabel="Freq (Hz)", ylabel="Phase Velocity",
                            clims=(0.0,1.0), linewidth=0.0, c=:thermal, title="Dispersion Image") # plot the normalized dispersion image
        Plots.plot!(DispersionCurve[1],DispersionCurve[2], line=(:black, 2.0), label="dispersion curve") # Plot the picked dispersion curve. This is nothing if 'none' picking was set
        if !isempty(plotfreqlimits)
            Plots.xlims!(plotfreqlimits)
        end
        Plots.scalefontsizes(3)
        p = Plots.plot(p1, p2, size=(1600, 800), layout=l)
        if !ispath(figdir)
            mkpath(figdir)
        end
        Plots.savefig(p, figdir*"/"*figname)
    end

    return (f, ct, normed, DispersionCurve)
end

end # module
