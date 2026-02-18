'use client'

import { RecipeForm } from '@/components/ui/recipe-form'
import { useRouter } from 'next/navigation'
import { auth } from '@/lib/firebase'
import { useAuthState } from 'react-firebase-hooks/auth'
import { createRecipe } from '@/lib/recipeUtils'

export default function CreateRecipePage() {
    const router = useRouter()
    const [user] = useAuthState(auth)

    const handleSubmit = async (data: any) => {
        // check isLogin
        if (!user) {
            alert('You must be logged in to create a recipe.')
            return
        }
        try {
            await createRecipe(user.uid, data)
            router.push('/')
        } catch (e) {
            console.error(e)
            alert('Failed to save recipe')
        }
    }

    return (
        <div className="container mx-auto py-10">
            <h1 className="text-3xl font-bold mb-8">Create New Recipe</h1>
            <RecipeForm onSubmit={handleSubmit} />
        </div>
    )
}
