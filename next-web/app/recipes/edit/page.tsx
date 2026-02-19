'use client'

import { useEffect, useState, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { auth } from '@/lib/firebase'
import { useAuthState } from 'react-firebase-hooks/auth'
import { getRecipe, updateRecipe, createRecipe } from '@/lib/recipeUtils'
import { RecipeForm } from '@/components/ui/recipe-form'
import { Recipe } from '@/types/recipe'

function EditRecipeContent() {
    const router = useRouter()
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

    const handleSubmit = async (data: any) => {
        if (!user || !recipe) return
        try {
            await updateRecipe(user.uid, { ...data, id: recipe.id })
            router.push('/')
        } catch (e) {
            console.error(e)
            alert('Failed to update recipe')
        }
    }

    const handleStartBrewing = (data: any) => {
        // Create a temporary recipe object
        const tempRecipe = { ...data, id: id || 'temp' }
        // Encode the recipe to base64
        const encodedRecipe = btoa(encodeURIComponent(JSON.stringify(tempRecipe)))
        // Navigate to the timer page with the encoded recipe
        router.push(`/recipes/timer?encoded=${encodedRecipe}`)
    }

    const handleSaveAsCopy = async (data: any) => {
        if (!user) return
        try {
            // Create a new recipe without ID (Firestore will generate one)
            // We strip the ID here by destructuring
            const { id: _, ...recipeData } = data
            await createRecipe(user.uid, {
                ...recipeData,
                name: `${data.name} (Copy)`,
                lastUsed: new Date().toISOString()
            })
            alert('Recipe copied successfully!')
            router.push('/')
        } catch (e) {
            console.error(e)
            alert('Failed to copy recipe')
        }
    }

    if (loading || isLoadingRecipe) return <div className="p-8">Loading...</div>
    if (!id) return <div className="p-8">Recipe ID is missing.</div>
    if (!recipe) return <div className="p-8">Recipe not found.</div>

    return (
        <div className="min-h-screen bg-gray-50 p-4 md:p-8">
            <div className="mx-auto max-w-4xl">
                <h1 className="text-3xl font-bold mb-8 text-gray-800">Edit Recipe</h1>
                <RecipeForm
                    defaultValues={recipe}
                    onSubmit={handleSubmit}
                    onStartBrewing={handleStartBrewing}
                    onSaveAsCopy={handleSaveAsCopy}
                />
            </div>
        </div>
    )
}

export default function EditRecipePage() {
    return (
        <Suspense fallback={<div>Loading...</div>}>
            <EditRecipeContent />
        </Suspense>
    )
}
