struct SensorData{T}
    device::T
    poll_interval::Float64
    isrunning::Threads.Atomic{Bool}
    task::Ref{Task}
end

function SensorData(device::T, poll_interval::Number=2.0) where T
    return SensorData{T}(device, poll_interval, Threads.Atomic{Bool}(false),
                         Ref{Task}())
end

const °C = 1.0 * Unitful.°C
const Percent = 1.0 * Unitful.percent
const μg_m³ = 1.0 * (Unitful.μg / Unitful.m^3)

const °C_Type = typeof(°C)
const Percent_Type = typeof(Percent)
const μg_m³_Type = typeof(μg_m³)

struct TemperatureSensor{T} <: AbstractSensor
    data::SensorData{T}
    name::Attribute{String}
    temperature::Attribute{°C_Type}
end

function TemperatureSensor(device::T; poll_interval=2.0) where T
    TemperatureSensor{T}(SensorData(device, poll_interval), string(T), 0.0Unitful.°C => Readonly)
end

struct TemperatureHumiditySensor{T} <: AbstractSensor
    data::SensorData{T}
    name::Attribute{String}
    temperature::Attribute{°C_Type}
    humidity::Attribute{Percent_Type}
end

function TemperatureHumiditySensor(device::T; poll_interval=2.0) where T
    TemperatureHumiditySensor{T}(SensorData(device, poll_interval), string(T), 0.0Unitful.°C => Readonly, 0.0Unitful.percent => Readonly)
end

struct DustSensor{T} <: AbstractSensor
    data::SensorData{T}
    name::Attribute{String}
    pm1::Attribute{μg_m³_Type}
    pm2_5::Attribute{μg_m³_Type}
    pm10::Attribute{μg_m³_Type}
end

function DustSensor(device::T; poll_interval=2.0) where T
    DustSensor{T}(SensorData(device, poll_interval), string(T), 0.0μg_m³ => Readonly, 0.0μg_m³ => Readonly, 0.0μg_m³ => Readonly)
end

"""
    sensor_data(sensor::AbstractSensor)::SensorData
Returns the sensor data struct
"""
function sensor_data(sensor::AbstractSensor)
    return sensor.data
end

function device(sensor::AbstractSensor)
    return sensor_data(sensor).device
end

"""
    poll_interval(sensor::AbstractSensor)
Returns the polling interval in Seconds
"""
function poll_interval(sensor::AbstractSensor)
    return sensor_data(sensor).poll_interval
end

"""
    isrunning(sensor::AbstractSensor)
Returns if true if the sensor polling loop is running
"""
function isrunning(sensor::AbstractSensor)
    return sensor_data(sensor).isrunning[]
end

"""
    read!(sensor::AbstractSensor)

Reads and updates the current sensor data!
Gets updated by read!(sensor)

Note: Expected to block as long as it takes to read the sensor!
"""
function Base.read!(sensor::AbstractSensor)
    error("read! not implemented for $(typeof(sensor)).
          This is part of the basic sensor interface and needs to be implemented")
end


function start!(sensor::AbstractSensor)
    # No need to start, if running already
    isrunning(sensor) && return
    data = sensor_data(sensor)
    data.isrunning[] = true
    data.task[] = @async begin
        try
            while isrunning(sensor)
                Base.read!(sensor)
                sleep(poll_interval(sensor))
            end
        catch e
            Base.show_backtrace(stderr, Base.catch_backtrace())
            Base.showerror(stderr, e)
        finally
            data.isrunning[] = false
        end
    end
    return data.task[]
end

function stop!(sensor::AbstractSensor)
    sensor_data(sensor).isrunning[] = false
    return
end
