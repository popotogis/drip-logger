'use client'

import { useEffect, useState, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { auth } from '@/lib/firebase'
import { useAuthState } from 'react-firebase-hooks/auth'
import { getRecipe } from '@/lib/recipeUtils'
import { TimerDisplay } from '@/components/timer/TimerDisplay'
import { Recipe } from '@/types/recipe'
import { Button } from '@/components/ui/button'
import { ArrowLeft } from 'lucide-react'
import Link from 'next/link'

function TimerPageContent() {
    const searchParams = useSearchParams()
    const id = searchParams.get('id')
    const encoded = searchParams.get('encoded')
    const [user, loading] = useAuthState(auth)
    const [recipe, setRecipe] = useState<Recipe | null>(null)
    const [isLoadingRecipe, setIsLoadingRecipe] = useState(true)

    useEffect(() => {
        // Wake Lock
        let wakeLock: WakeLockSentinel | null = null;
        const requestWakeLock = async () => {
            try {
                if ('wakeLock' in navigator) {
                    wakeLock = await navigator.wakeLock.request('screen');
                }
            } catch (err: any) {
                console.error(`${err.name}, ${err.message}`);
            }
        };
        requestWakeLock();

        const handleVisibilityChange = () => {
            if (wakeLock !== null && document.visibilityState === 'visible') {
                requestWakeLock();
            }
        };
        document.addEventListener('visibilitychange', handleVisibilityChange);

        return () => {
            if (wakeLock) wakeLock.release();
            document.removeEventListener('visibilitychange', handleVisibilityChange);
        };
    }, []);

    useEffect(() => {
        const fetchRecipe = async () => {
            if (encoded) {
                try {
                    const decoded = JSON.parse(decodeURIComponent(atob(encoded)))
                    setRecipe(decoded)
                    setIsLoadingRecipe(false)
                    return
                } catch (e) {
                    console.error('Failed to decode recipe', e)
                }
            }

            if (user && id) {
                const fetched = await getRecipe(user.uid, id)
                setRecipe(fetched)
                setIsLoadingRecipe(false)
            } else if (!id) {
                setIsLoadingRecipe(false)
            }
        }
        if (!loading) fetchRecipe()
    }, [user, id, encoded, loading])

    if (loading || isLoadingRecipe) return <div className="p-10">Loading...</div>
    if (!id && !encoded && !recipe) return <div className="p-10">Recipe ID or valid data is missing.</div>
    if (!recipe) return <div className="p-10">Recipe not found.</div>

    return (
        <div className="container mx-auto py-10 px-4">
            <div className="mb-6">
                <Link href="/">
                    <Button variant="ghost" className="pl-0">
                        <ArrowLeft className="mr-2 h-4 w-4" />
                        Back to List
                    </Button>
                </Link>
            </div>

            <h1 className="text-3xl font-bold mb-2 text-center">{recipe.name}</h1>
            <p className="text-center text-gray-500 mb-8">
                {recipe.beanWeightGrams}g beans / {recipe.totalWaterAmount}ml water
            </p>

            <div className="max-w-md mx-auto bg-white rounded-xl shadow-lg p-8">
                <TimerDisplay recipe={recipe} />
            </div>
        </div>
    )
}

export default function TimerPage() {
    return (
        <Suspense fallback={<div>Loading...</div>}>
            <TimerPageContent />
        </Suspense>
    )
}
