@compile_workload begin
    system_uuid()
    add_processor_callback!("__cpu_thread_1__") do
        ThreadProc(1, 1)
    end
    t1 = @spawn 1+1
    t2 = spawn(+, 1, t1)
    fetch(t2)
    spawn() do
        Sch.halt!(sch_handle())
    end
    while Sch.EAGER_INIT[]
        sleep(0.1)
    end
    Sch.EAGER_CONTEXT[] = nothing
    GC.gc()
    yield()
    lock(Sch.ERRORMONITOR_TRACKED) do tracked
        if all(t->istaskdone(t) || istaskfailed(t), tracked)
            empty!(tracked)
            return
        end
        for t in tracked
            Base.throwto(t, InterruptException())
        end
    end
    MemPool.exit_hook()
    GC.gc()
    yield()
    @assert isempty(Sch.WORKER_MONITOR_CHANS)
    @assert isempty(Sch.WORKER_MONITOR_TASKS)
end
