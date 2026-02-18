'use client'

import { useEffect, useState, use } from 'react'
import { useRouter } from 'next/navigation'
import { auth } from '@/lib/firebase'
import { useAuthState } from 'react-firebase-hooks/auth'
import { getRecipe, updateRecipe } from '@/lib/recipeUtils'
import { RecipeForm } from '@/components/ui/recipe-form'
import { Recipe } from '@/types/recipe'

export default function EditRecipePage({ params }: { params: Promise<{ id: string }> }) {
    const router = useRouter()
    const { id } = use(params)
    const [user, loading] = useAuthState(auth)
    const [recipe, setRecipe] = useState<Recipe | null>(null)
    const [isLoadingRecipe, setIsLoadingRecipe] = useState(true)

    useEffect(() => {
        const fetchRecipe = async () => {
            if (user && id) {
                const fetched = await getRecipe(user.uid, id)
                setRecipe(fetched)
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

    if (loading || isLoadingRecipe) return <div>Loading...</div>
    if (!recipe) return <div>Recipe not found.</div>

    return (
        <div className="container mx-auto py-10">
            <h1 className="text-3xl font-bold mb-8">Edit Recipe</h1>
            <RecipeForm defaultValues={recipe} onSubmit={handleSubmit} />
        </div>
    )
}