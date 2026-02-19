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
        <div className="container mx-auto py-10 px-4">
            <div className="flex justify-between items-center mb-6">
                <div className="flex items-center gap-4">
                    <Link href="/">
                        <Button variant="ghost" size="icon">
                            <ArrowLeft className="h-6 w-6" />
                        </Button>
                    </Link>
                    <h1 className="text-3xl font-bold">Beans</h1>
                </div>
                <Link href="/beans/create">
                    <Button>
                        <Plus className="mr-2 h-4 w-4" />
                        Add Bean
                    </Button>
                </Link>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-3 gap-4">
                {beans.map(bean => (
                    <Link href={`/beans/edit?id=${bean.id}`} key={bean.id} className="block group relative">
                        <div className="border rounded-lg p-4 bg-white shadow-sm hover:shadow-md transition">
                            <h2 className="text-xl font-bold mb-1">{bean.name}</h2>
                            <p className="text-sm text-gray-500 mb-2">{bean.roaster}</p>
                            <div className="text-sm space-y-1">
                                {bean.origin && <p>Origin: {bean.origin}</p>}
                                <p>Roast: {bean.roastLevel}</p>
                            </div>

                            {/* actions */}
                            <div className="absolute top-4 right-4 opacity-0 group-hover:opacity-100 transition flex gap-2">
                                <Button size="icon" variant="ghost" className="h-8 w-8 text-gray-400 hover:text-red-500" onClick={(e) => handleDelete(e, bean.id)}>
                                    <Trash2 className="h-4 w-4" />
                                </Button>
                            </div>
                        </div>
                    </Link>
                ))}
            </div>
        </div>
    )
}