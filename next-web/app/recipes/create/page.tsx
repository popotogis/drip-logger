'use client'

import { RecipeForm } from '@/components/ui/recipe-form'
import { useRouter } from 'next/navigation'

export default function CreateRecipePage() {
    const router = useRouter()

    const handleSubmit = async (data: any) => {
        console.log('Submitted data:', data)
        alert('Recipe data checked in console! (Saving not implemented yet)')
        // TODO: Implement Firestore saving logic
        // await createRecipe(data)
        // router.push('/')
    }

    return (
        <div className="container mx-auto py-10">
            <h1 className="text-3xl font-bold mb-8">Create New Recipe</h1>
            <RecipeForm onSubmit={handleSubmit} />
        </div>
    )
}
