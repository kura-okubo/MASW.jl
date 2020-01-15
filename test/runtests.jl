using MASW
using JLD2
using Test

@testset "MASW.jl" begin
    # Write your own tests here.

    # Travis is not working with Pyplot.
    #Plots.pyplot()

    #===
    # example to run masw(). Example and SampleData are based on matlab script written by John Schuh.

    Matlab script: Copyright (c) 2018, John Schuh All rights reserved.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
    INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    •    John Schuh (2020). MASW Dispersion Curve (https://www.mathworks.com/matlabcentral/fileexchange/65138-masw-dispersion-curve), MATLAB Central File Exchange.
          Retrieved January 14, 2020.
    ===#
    curdir = pwd()
    fi = jldopen(curdir*"/../example/SampleData.jld", "r")
    U = fi["suma_sg"]
    close(fi)

    fs=1000; # sampling frequency Hz
    min_x = 1; # min offset [m] of reciever spread
    max_x = 100; # max offset [m] of reciever spread
    d_x = 2; # distance between receivers [m]

    x = min_x:d_x:max_x; # spatial sampling vector (receiver position)
    t=1/fs:1/fs:length(U[:,1])/fs;  # time vector in seconds

    # figdir = "./"
    # figname = "dispersionimage.png"

    ct=300:1:1200;
    freqlimits=(15.0, 80.0);

    (f, ct, Udisp, DispersionCurve)=masw(U, x, t, ct, plotfreqlimits=freqlimits)

    @test f[1] == 0.0
    @test ct[1] == 300
end
