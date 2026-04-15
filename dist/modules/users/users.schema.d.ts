import { z } from 'zod';
export declare const createUserSchema: z.ZodObject<{
    name: z.ZodString;
    email: z.ZodNullable<z.ZodOptional<z.ZodString>>;
    username: z.ZodString;
    password: z.ZodString;
    role: z.ZodDefault<z.ZodNativeEnum<{
        readonly ADMIN: "ADMIN";
        readonly MANAGER: "MANAGER";
        readonly OPERATOR: "OPERATOR";
        readonly VIEWER: "VIEWER";
    }>>;
}, "strip", z.ZodTypeAny, {
    password: string;
    role: "ADMIN" | "MANAGER" | "OPERATOR" | "VIEWER";
    name: string;
    username: string;
    email?: string | null | undefined;
}, {
    password: string;
    name: string;
    username: string;
    email?: string | null | undefined;
    role?: "ADMIN" | "MANAGER" | "OPERATOR" | "VIEWER" | undefined;
}>;
export declare const updateUserSchema: z.ZodObject<{
    name: z.ZodOptional<z.ZodString>;
    email: z.ZodNullable<z.ZodOptional<z.ZodString>>;
    username: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    email?: string | null | undefined;
    name?: string | undefined;
    username?: string | undefined;
}, {
    email?: string | null | undefined;
    name?: string | undefined;
    username?: string | undefined;
}>;
export declare const updateRoleSchema: z.ZodObject<{
    role: z.ZodNativeEnum<{
        readonly ADMIN: "ADMIN";
        readonly MANAGER: "MANAGER";
        readonly OPERATOR: "OPERATOR";
        readonly VIEWER: "VIEWER";
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