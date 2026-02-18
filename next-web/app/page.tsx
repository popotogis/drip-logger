'use client'

import { GoogleAuthProvider, signInWithPopup, signOut } from 'firebase/auth'
import { auth, db } from '@/lib/firebase'
import { useAuthState } from 'react-firebase-hooks/auth'
import { useCollection } from 'react-firebase-hooks/firestore'
import { collection, query, orderBy } from 'firebase/firestore'
import Link from 'next/link'
import { Plus, Trash2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { deleteRecipe } from '@/lib/recipeUtils'

export default function Home() {
  const [user, loading, error] = useAuthState(auth)

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <p>Loading...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex h-screen items-center justify-center text-red-500">
        <p>Error: {error.message}</p>
      </div>
    )
  }
  if (!user) {
    return <LoginView />
  }

  return <RecipeListView uid={user.uid} />
}

function LoginView() {
  const signIn = () => {
    signInWithPopup(auth, new GoogleAuthProvider())
  }

  return (
    <div className="flex h-screen flex-col items-center justify-center space-y-4">
      <h1 className="text-4xl font-bold">Drip Logger</h1>
      <p className="text-gray-600">Please sign in to view your recipes.</p>
      <button
        onClick={signIn}
        className="rounded bg-blue-500 px-6 py-2 font-bold text-white hover:bg-blue-600 transition"
      >
        Sign in with Google
      </button>
    </div>
  )
}

function RecipeListView({ uid }: { uid: string }) {
  const [snapshot, loading, error] = useCollection(
    query(collection(db, 'users', uid, 'recipes'), orderBy('lastUsed', 'desc'))
  )

  const logout = () => signOut(auth)

  if (loading) return <div className="p-8">Loading recipes...</div>
  if (error) return <div className="p-8 text-red-500">Error: {error.message}</div>

  const recipes = snapshot?.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }))

  const handleDelete = async (e: React.MouseEvent, recipeId: string) => {
    e.preventDefault()
    e.stopPropagation()
    if (!confirm('Are you sure you want to delete this recipe?')) return

    try {
      await deleteRecipe(uid, recipeId)
    } catch (err) {
      console.error(err)
      alert('Failed to delete')
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-4xl">
        <div className="mb-8 flex items-center justify-between">
          <h1 className="text-3xl font-bold text-gray-800">My Recipes</h1>
          <div className="flex gap-4">

            {/* create new recipe button */}
            <Link href="/recipes/create">
              <Button>
                <Plus className="mr-2 h-4 w-4" />
                Create Recipe
              </Button>
            </Link>

            {/* sign out button */}
            <button onClick={logout} className="text-sm text-gray-500 hover:text-red-500">
              Sign out
            </button>
          </div>
        </div>

        {recipes && recipes.length > 0 ? (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {recipes.map((recipe: any) => (
              <div
                key={recipe.id}
                className="relative group rounded-lg bg-white p-6 shadow hover:shadow-md transition"
              >
                {/* recipe card */}
                <Link href={`/recipes/edit?id=${recipe.id}`} className="block">
                  <h2 className="mb-2 text-xl font-bold text-gray-900">{recipe.name}</h2>
                  <div className="flex items-baseline space-x-2 text-gray-600">
                    <span className="text-sm">beans: {recipe.beanWeightGrams}g</span>
                    <span>/</span>
                    <span className="text-sm">water: {recipe.totalWaterAmount}ml</span>
                  </div>
                  {recipe.note && (
                    <p className="mt-4 text-sm text-gray-500 line-clamp-2">{recipe.note}</p>
                  )}
                </Link>

                {/* delete button */}
                <button
                  onClick={(e) => handleDelete(e, recipe.id)}
                  className="absolute top-4 right-4 p-2 text-gray-400 hover:text-red-500 opacity-0 group-hover:opacity-100 transition"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center text-gray-500">
            <p>No recipes found.</p>
            <p className="text-sm mb-4">Create your first recipe!</p>
            <Link href="/recipes/create">
              <Button variant="outline">
                <Plus className="mr-2 h-4 w-4" />
                Create Recipe
              </Button>
            </Link>
          </div>
        )}
      </div>
    </div>
  )
}
