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
    const [user, loading] = useAuthState(auth)
    const [recipe, setRecipe] = useState<Recipe | null>(null)
    const [isLoadingRecipe, setIsLoadingRecipe] = useState(true)

    useEffect(() => {
        const fetchRecipe = async () => {
            if (user && id) {
                const fetched = await getRecipe(user.uid, id)
                setRecipe(fetched)
                setIsLoadingRecipe(false)
            } else if (!id) {
                setIsLoadingRecipe(false)
            }
        }
        if (!loading) fetchRecipe()
    }, [user, id, loading])

    if (loading || isLoadingRecipe) return <div className="p-10">Loading...</div>
    if (!id) return <div className="p-10">Recipe ID is missing.</div>
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
