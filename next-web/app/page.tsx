'use client'

import { GoogleAuthProvider, signInWithPopup, signOut } from 'firebase/auth'
import { auth, db } from '@/lib/firebase'
import { useAuthState } from 'react-firebase-hooks/auth'
import { useCollection } from 'react-firebase-hooks/firestore'
import { collection, query, orderBy } from 'firebase/firestore'

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

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-4xl">
        <div className="mb-8 flex items-center justify-between">
          <h1 className="text-3xl font-bold text-gray-800">My Recipes</h1>
          <button onClick={logout} className="text-sm text-gray-500 hover:text-red-500">
            Sign out
          </button>
        </div>

        {recipes && recipes.length > 0 ? (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {recipes.map((recipe: any) => (
              <div
                key={recipe.id}
                className="rounded-lg bg-white p-6 shadow hover:shadow-md transition"
              >
                <h2 className="mb-2 text-xl font-bold text-gray-900">{recipe.name}</h2>
                <div className="flex items-baseline space-x-2 text-gray-600">
                  <span className="font-semibold">{recipe.beanWeightGrams}g</span>
                  <span className="text-sm">beans</span>
                  <span>/</span>
                  <span className="text-sm">water</span>
                </div>
                {recipe.note && (
                  <p className="mt-4 text-sm text-gray-500 line-clamp-2">{recipe.note}</p>
                )}
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center text-gray-500">
            <p>No recipes found.</p>
            <p className="text-sm">Create recipes in the Flutter app first.</p>
          </div>
        )}
      </div>
    </div>
  )
}
