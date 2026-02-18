import { useState, useEffect, useRef, useCallback } from 'react'
import * as WorkerTimers from 'worker-timers'
import { Recipe } from '@/types/recipe'

export const useDripTimer = (recipe: Recipe) => {
    const [elapsedTime, setElapsedTime] = useState(0)
    const [stepElapsedTime, setStepElapsedTime] = useState(0)
    const [currentStepIndex, setCurrentStepIndex] = useState(0)
    const [isActive, setIsActive] = useState(false)
    const timerRef = useRef<number | null>(null)
    const currentStep = recipe.steps[currentStepIndex]
    const isLastStep = currentStepIndex === recipe.steps.length - 1
    const tick = useCallback(() => {
        setElapsedTime(prev => prev + 1)
        setStepElapsedTime(prev => prev + 1)
    }, [])

    const start = useCallback(() => {
        if (!isActive) {
            setIsActive(true)
            timerRef.current = WorkerTimers.setInterval(tick, 1000)
        }
    }, [isActive, tick])

    const pause = useCallback(() => {
        if (isActive && timerRef.current !== null) {
            WorkerTimers.clearInterval(timerRef.current)
            timerRef.current = null
            setIsActive(false)
        }
    }, [isActive])

    const nextStep = useCallback(() => {
        if (!isLastStep) {
            setCurrentStepIndex(prev => prev + 1)
            setStepElapsedTime(0)
        } else {
            pause()
        }
    }, [isLastStep, pause])

    const reset = useCallback(() => {
        pause()
        setElapsedTime(0)
        setStepElapsedTime(0)
        setCurrentStepIndex(0)
    }, [pause])

    useEffect(() => {
        return () => {
            if (timerRef.current !== null) {
                WorkerTimers.clearInterval(timerRef.current)
            }
        }
    }, [])

    return {
        elapsedTime,
        stepElapsedTime,
        currentStepIndex,
        currentStep,
        isActive,
        isLastStep,
        start,
        pause,
        reset,
        nextStep,
    }
}