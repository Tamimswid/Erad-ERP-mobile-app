import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../bloc/auth_cubit.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_isLogin) {
        context.read<AuthCubit>().login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        context.read<AuthCubit>().register(
          _emailController.text.trim(),
          _passwordController.text,
          _businessNameController.text.trim(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and Title
              Image.asset(AppAssets.logo, width: 60, height: 60),
              const SizedBox(height: 10),
              Text(
                'إراد',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
        
              Text(
                'نظام المحاسبة والمخزون',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
        
              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(sc.LucideIcons.mail),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'البريد الإلكتروني مطلوب';
                  }
                  if (!value.contains('@')) {
                    return 'البريد الإلكتروني غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
        
              // Business Name Field (only for registration)
              if (!_isLogin) ...[
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الشركة',
                    prefixIcon: Icon(sc.LucideIcons.building2),
                  ),
                  validator: (value) {
                    if (!_isLogin &&
                        (value == null || value.trim().isEmpty)) {
                      return 'اسم الشركة مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
        
              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(sc.LucideIcons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? sc.LucideIcons.eye
                          : sc.LucideIcons.eyeOff,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'كلمة المرور مطلوبة';
                  }
                  if (value.length < 8) {
                    return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
        
              // Submit Button
              sc.Button(
                style: sc.ButtonStyle.primary(),
                onPressed: state is AuthLoading ? null : _submitForm,
                child: state is AuthLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء حساب'),
              ),
              const SizedBox(height: 16),
        
              // Toggle Login/Register
              sc.Button(
                style: sc.ButtonStyle.ghost(),
                onPressed: state is AuthLoading
                    ? null
                    : () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                child: Text(
                  _isLogin
                      ? 'ليس لديك حساب؟ إنشاء حساب'
                      : 'لديك حساب بالفعل؟ تسجيل الدخول',
                ),
              ),
        
              // Forgot Password (only for login)
              if (_isLogin) ...[
                const SizedBox(height: 8),
                sc.Button(
                  style: sc.ButtonStyle.ghost(),
                  onPressed: state is AuthLoading
                      ? null
                      : () {
                          _showForgotPasswordDialog(context);
                        },
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة كلمة المرور'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('أدخل بريدك الإلكتروني لإرسال رابط استعادة كلمة المرور'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(sc.LucideIcons.mail),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  sc.Button(
                    style: sc.ButtonStyle.ghost(),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  sc.Button(
                    style: sc.ButtonStyle.primary(),
                    onPressed: () {
                      if (emailController.text.trim().isNotEmpty) {
                        context.read<AuthCubit>().forgotPassword(
                          emailController.text.trim(),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('إرسال'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
