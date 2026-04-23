'use client'

import { RecipeForm } from '@/components/ui/recipe-form'
import { useRouter } from 'next/navigation'
import { auth } from '@/lib/firebase'
import { useAuthState } from 'react-firebase-hooks/auth'
import { createRecipe } from '@/lib/recipeUtils'
import { Button } from '@/components/ui/button'
import { ArrowLeft } from 'lucide-react'
import Link from 'next/link'

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
        <div className="min-h-screen bg-gray-50 p-4 md:p-8">
            <div className="mx-auto max-w-4xl">
                <Link href="/" className="mb-6 inline-block">
                    <Button variant="ghost" className="pl-0">
                        <ArrowLeft className="mr-2 h-4 w-4" />
                        Back
                    </Button>
                </Link>
                <h1 className="text-3xl font-bold mb-8 text-gray-800">Create New Recipe</h1>
                <RecipeForm onSubmit={handleSubmit} />
            </div>
        </div>
    )
}
