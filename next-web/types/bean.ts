import { Timestamp } from 'firebase/firestore'

export interface Bean {
    id: string
    name: string
    roaster: string
    roastLevel?: string
    origin?: string
    process?: string
    variety?: string
    roastDate?: string
    note?: string
    createdAt?: Timestamp
    updatedAt?: Timestamp
}