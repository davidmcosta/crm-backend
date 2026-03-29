import { CreateUserInput, UpdateUserInput, UpdateRoleInput, ChangePasswordInput } from './users.schema';
export declare function listUsers(): Promise<{
    email: string;
    id: string;
    name: string;
    role: import(".prisma/client").$Enums.UserRole;
    active: boolean;
    createdAt: Date;
}[]>;
export declare function getUserById(id: string): Promise<{
    email: string;
    id: string;
    name: string;
    role: import(".prisma/client").$Enums.UserRole;
    active: boolean;
    createdAt: Date;
    _count: {
        orders: number;
    };
}>;
export declare function createUser(data: CreateUserInput): Promise<{
    email: string;
    id: string;
    name: string;
    role: import(".prisma/client").$Enums.UserRole;
    active: boolean;
    createdAt: Date;
}>;
export declare function updateUser(id: string, data: UpdateUserInput): Promise<{
    email: string;
    id: string;
    name: string;
    role: import(".prisma/client").$Enums.UserRole;
    active: boolean;
}>;
export declare function updateUserRole(id: string, data: UpdateRoleInput): Promise<{
    email: string;
    id: string;
    name: string;
    role: import(".prisma/client").$Enums.UserRole;
}>;
export declare function deactivateUser(id: string, requestingUserId: string): Promise<{
    id: string;
    name: string;
    active: boolean;
}>;
export declare function changePassword(id: string, data: ChangePasswordInput): Promise<{
    message: string;
}>;
//# sourceMappingURL=users.service.d.ts.map