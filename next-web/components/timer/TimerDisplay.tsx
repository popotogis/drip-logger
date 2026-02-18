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

    return (
        <div className="flex flex-col items-center space-y-6">

            {/* main timer */}
            <div className="text-6xl font-mono font-semibold">
                {formatTime(elapsedTime)}
            </div>

            {/* current step */}
            <div className="text-center">
                <p className="text-xl font-semibold mb-2">Step {currentStepIndex + 1}: Pour {currentStep.waterAmount}g</p>
                <p className="text-gray-500">wait: {currentStep.waitTime}</p>
            </div>

            {/* progress bar */}
            <div className="w-full bg-gray-200 rounded-full h-4 relative overflow-hidden">
                <div className="bg-blue-500 h-4 transition-all duration-1000 ease-linear"
                    style={{ width: `${progress}%` }}
                />
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