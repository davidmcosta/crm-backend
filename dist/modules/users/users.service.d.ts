import { CreateUserInput, UpdateUserInput, UpdateRoleInput, ChangePasswordInput } from './users.schema';
export declare function listUsers(): Promise<any>;
export declare function getUserById(id: string): Promise<any>;
export declare function createUser(data: CreateUserInput): Promise<any>;
export declare function updateUser(id: string, data: UpdateUserInput): Promise<any>;
export declare function updateUserRole(id: string, data: UpdateRoleInput): Promise<any>;
export declare function deactivateUser(id: string, requestingUserId: string): Promise<any>;
export declare function adminResetPassword(id: string, newPassword: string): Promise<{
    message: string;
}>;
export declare function changePassword(id: string, data: ChangePasswordInput): Promise<{
    message: string;
}>;
//# sourceMappingURL=users.service.d.ts.map