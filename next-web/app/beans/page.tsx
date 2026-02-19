'use client'

import { useEffect, useState } from 'react'
import { auth } from '@/lib/firebase'
import { useAuthState } from 'react-firebase-hooks/auth'
import { Bean } from '@/types/bean'
import { getBeans, deleteBean } from '@/lib/beanUtils'
import { Button } from '@/components/ui/button'
import Link from 'next/link'
import { Plus, Trash2, Edit, ArrowLeft } from 'lucide-react'
import { useRouter } from 'next/navigation'

export default function BeanListPage() {
    const [user, loading] = useAuthState(auth)
    const [beans, setBeans] = useState<Bean[]>([])
    const router = useRouter()

    useEffect(() => {
        if (user) {
            getBeans(user.uid).then(setBeans)
        }
    }, [user])

    const handleDelete = async (e: React.MouseEvent, beanId: string) => {
        e.preventDefault()
        if (!user || !confirm('Are you sure you want to delete this bean?')) return
        try {
            await deleteBean(user.uid, beanId)
            setBeans(prev => prev.filter(b => b.id !== beanId))
        } catch (e) {
            console.error(e)
            alert('Failed to delete bean')
        }
    }

    if (loading) return <div className="p-8">Loading...</div>
    if (!user) return <div className="p-8">Please sign in.</div>

    return (
        <div className="min-h-screen bg-gray-50 p-4 md:p-8">
            <div className="mx-auto max-w-4xl">
                <div className="mb-8 flex items-center justify-between">
                    <h1 className="text-3xl font-bold text-gray-800">Beans</h1>
                    <Link href="/beans/create">
                        <Button>
                            <Plus className="mr-2 h-4 w-4" />
                            Add Bean
                        </Button>
                    </Link>
                </div>

                {beans && beans.length > 0 ? (
                    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                        {beans.map(bean => (
                            <Link href={`/beans/edit?id=${bean.id}`} key={bean.id} className="block group relative">
                                <div className="rounded-lg bg-white p-6 shadow-sm border border-gray-100 active:border-blue-500 transition-colors">
                                    <h2 className="text-xl font-bold mb-1 text-gray-900">{bean.name}</h2>
                                    <p className="text-sm text-gray-500 mb-2">{bean.roaster}</p>
                                    <div className="text-sm space-y-1 text-gray-600">
                                        {bean.origin && <p>Origin: {bean.origin}</p>}
                                        <p>Roast: {bean.roastLevel}</p>
                                    </div>

                                    {/* actions - Align with Home Page style */}
                                    <button
                                        onClick={(e) => handleDelete(e, bean.id)}
                                        className="absolute top-4 right-4 p-3 text-gray-300 hover:text-red-500 transition-colors"
                                        aria-label="Delete bean"
                                    >
                                        <Trash2 className="h-5 w-5" />
                                    </button>
                                </div>
                            </Link>
                        ))}
                    </div>
                ) : (
                    <div className="text-center text-gray-500 mt-20">
                        <p>No beans found.</p>
                        <p className="text-sm mb-4">Add your first bean!</p>
                        <Link href="/beans/create">
                            <Button variant="outline">
                                <Plus className="mr-2 h-4 w-4" />
                                Add Bean
                            </Button>
                        </Link>
                    </div>
                )}
            </div>
        </div>
    )
}