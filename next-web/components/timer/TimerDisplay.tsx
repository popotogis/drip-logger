import { Button } from '@/components/ui/button'
import { Play, Pause, SkipForward, RotateCcw } from 'lucide-react'
import { Recipe } from '@/types/recipe'
import { useDripTimer } from '@/hooks/useDripTimer'

const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60).toString().padStart(2, '0')
    const s = (seconds % 60).toString().padStart(2, '0')
    return `${m}:${s}`
}

export const TimerDisplay = ({ recipe }: { recipe: Recipe }) => {
    const {
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
    } = useDripTimer(recipe)

    const progress = Math.min((stepElapsedTime / currentStep.waitTime) * 100, 100)

    // Calculate cumulative water amount up to current step
    const targetWaterAmount = recipe.steps
        .slice(0, currentStepIndex + 1)
        .reduce((acc, step) => acc + step.waterAmount, 0)

    return (
        <div className="flex flex-col items-center space-y-6">

            {/* main timer */}
            <div className="text-6xl font-mono font-semibold">
                {formatTime(elapsedTime)}
            </div>

            {/* current step */}
            <div className="text-center">
                <p className="text-xl font-semibold mb-2">Step {currentStepIndex + 1}: Target {targetWaterAmount}g</p>
                <p className="text-gray-500">wait: {currentStep.waitTime}s</p>
            </div>

            {/* progress bar */}
            {/* Added margin-top to make room for time labels */}
            <div className="w-full h-4 relative mt-8">
                {/* Background Track & Fill (Overflow Hidden) */}
                <div className="absolute inset-0 bg-gray-200 rounded-full overflow-hidden">
                    <div
                        className="bg-blue-500 h-full transition-all duration-1000 ease-linear absolute top-0 left-0"
                        style={{ width: `${Math.min((elapsedTime / recipe.steps.reduce((acc, s) => acc + s.waitTime, 0)) * 100, 100)}%` }}
                    />
                </div>

                {/* Step markers (Overlay on top of track, no overflow hidden so labels show) */}
                {recipe.steps.map((step, index) => {
                    const totalWaitTime = recipe.steps.reduce((acc, s) => acc + s.waitTime, 0)
                    const prevStepsWaitTime = recipe.steps.slice(0, index + 1).reduce((acc, s) => acc + s.waitTime, 0)
                    const positionPercent = (prevStepsWaitTime / totalWaitTime) * 100

                    // Don't show marker for the very last step (100%) but show the time label
                    const isLast = index === recipe.steps.length - 1

                    return (
                        <div
                            key={index}
                            className={`absolute top-0 bottom-0 z-10 ${isLast ? 'w-0' : 'w-0.5 bg-white'}`}
                            style={{ left: `${positionPercent}%` }}
                        >
                            <div className="absolute bottom-full mb-1 left-1/2 transform -translate-x-1/2 text-xs text-gray-500 font-mono whitespace-nowrap">
                                {formatTime(prevStepsWaitTime)}
                            </div>
                        </div>
                    )
                })}
            </div>

            {/* operation button */}
            <div className="flex gap-4">
                <Button variant="outline" size="icon" onClick={reset}>
                    <RotateCcw className="h-6 w-6" />
                </Button>

                <Button
                    size="lg"
                    className="w-24 h-24 rounded-full"
                    onClick={!isActive ? start : nextStep}
                    disabled={isLastStep && isActive}
                >
                    {!isActive ? <Play className="h-10 w-10 ml-1" /> : <SkipForward className="h-10 w-10" />}
                </Button>

                <Button variant="outline" size="icon" onClick={isActive ? pause : undefined} disabled={!isActive} className="opacity-50">
                    <Pause className="h-6 w-6" />
                </Button>
            </div>
        </div>
    )
}