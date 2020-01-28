module SmartHomy

using JSServe, Observables
using Base: RefValue
using Markdown
using Colors

abstract type SmartDevice end
abstract type AbstractLight <: SmartDevice end
abstract type AbstractPlug <: SmartDevice end
abstract type AbstractSensor <: SmartDevice end

include("device_locks.jl")
include("smartdevice.jl")
include("lights.jl")
include("plugs.jl")
include("sensors.jl")

end