import { z } from 'zod';
export declare const createUserSchema: z.ZodObject<{
    name: z.ZodString;
    email: z.ZodString;
    password: z.ZodString;
    role: z.ZodDefault<z.ZodNativeEnum<{
        ADMIN: "ADMIN";
        MANAGER: "MANAGER";
        OPERATOR: "OPERATOR";
        VIEWER: "VIEWER";
    }>>;
}, "strip", z.ZodTypeAny, {
    email: string;
    password: string;
    name: string;
    role: "ADMIN" | "MANAGER" | "OPERATOR" | "VIEWER";
}, {
    email: string;
    password: string;
    name: string;
    role?: "ADMIN" | "MANAGER" | "OPERATOR" | "VIEWER" | undefined;
}>;
export declare const updateUserSchema: z.ZodObject<{
    name: z.ZodOptional<z.ZodString>;
    email: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    email?: string | undefined;
    name?: string | undefined;
}, {
    email?: string | undefined;
    name?: string | undefined;
}>;
export declare const updateRoleSchema: z.ZodObject<{
    role: z.ZodNativeEnum<{
        ADMIN: "ADMIN";
        MANAGER: "MANAGER";
        OPERATOR: "OPERATOR";
        VIEWER: "VIEWER";
    }>;
}, "strip", z.ZodTypeAny, {
    role: "ADMIN" | "MANAGER" | "OPERATOR" | "VIEWER";
}, {
    role: "ADMIN" | "MANAGER" | "OPERATOR" | "VIEWER";
}>;
export declare const changePasswordSchema: z.ZodObject<{
    currentPassword: z.ZodString;
    newPassword: z.ZodString;
}, "strip", z.ZodTypeAny, {
    currentPassword: string;
    newPassword: string;
}, {
    currentPassword: string;
    newPassword: string;
}>;
export type CreateUserInput = z.infer<typeof createUserSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
export type UpdateRoleInput = z.infer<typeof updateRoleSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
//# sourceMappingURL=users.schema.d.ts.map