'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Home, Coffee, Settings, PlusCircle } from 'lucide-react'
import { cn } from '@/lib/utils'

export function BottomNav() {
    const pathname = usePathname()

    // Hide bottom nav on specific pages if needed (e.g. Timer)
    // if (pathname.includes('/timer')) return null

    const navItems = [
        { href: '/', label: 'Home', icon: Home },
        { href: '/beans', label: 'Beans', icon: Coffee },
        // Placeholder for future settings or other features
        // { href: '/settings', label: 'Settings', icon: Settings },
    ]

    return (
        <div className="fixed bottom-0 left-0 right-0 z-50 bg-background border-t border-border pb-safe">
            <nav className="flex items-center justify-around h-16">
                {navItems.map((item) => {
                    const isActive = pathname === item.href
                    return (
                        <Link
                            key={item.href}
                            href={item.href}
                            className={cn(
                                "flex flex-col items-center justify-center w-full h-full space-y-1",
                                isActive ? "text-primary" : "text-muted-foreground hover:text-foreground"
                            )}
                        >
                            <item.icon className="h-6 w-6" />
                            <span className="text-xs font-medium">{item.label}</span>
                        </Link>
                    )
                })}
            </nav>
        </div>
    )
}
