import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../domain/auth_failure.dart';
import 'auth_view_model.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.viewModel,
    required this.onAuthenticated,
    super.key,
  });

  final AuthViewModel viewModel;
  final Future<void> Function() onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  /// The last code the field submitted on its own. The button stays reachable
  /// while a code is complete, so without this the same code could be sent
  /// twice — once by the sixth keystroke and once by the tap that follows.
  String? _autoSubmittedOtp;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onOtpChanged(String value) {
    if (value.length < 6) {
      _autoSubmittedOtp = null;
      return;
    }
    if (_autoSubmittedOtp == value) return;
    _autoSubmittedOtp = value;
    _submit();
  }

  Future<void> _submit() async {
    if (widget.viewModel.isBusy) return;
    FocusScope.of(context).unfocus();
    if (widget.viewModel.step == AuthStep.email) {
      await widget.viewModel.requestOtp(_emailController.text);
      return;
    }
    final session = await widget.viewModel.verifyOtp(_otpController.text);
    if (session != null) await widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final otpStep = widget.viewModel.step == AuthStep.otp;
        final actionLabel = otpStep
            ? context.ota(
                'authVerifyCodeAction',
                tr: 'Kodu doğrula',
                en: 'Verify code',
              )
            : context.ota(
                'authSendCodeAction',
                tr: 'Kod gönder',
                en: 'Send code',
              );
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: AppColors.lime,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_open_rounded),
                      ),
                      const SizedBox(height: AppSpacing.x28),
                      Text(
                        otpStep
                            ? context.ota(
                                'authOtpTitle',
                                tr: 'E-postandaki kodu gir.',
                                en: 'Enter the code in your email.',
                              )
                            : context.ota(
                                'authEmailTitle',
                                tr: 'İlerlemeni cihazların arasında koru.',
                                en: 'Keep your progress across devices.',
                              ),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        otpStep
                            ? context.ota(
                                'authOtpBody',
                                tr: 'Altı haneli kodu {email} adresine gönderdik.',
                                en: 'We sent a six-digit code to {email}.',
                                replacements: {
                                  'email': _maskEmail(widget.viewModel.email),
                                },
                              )
                            : context.ota(
                                'authEmailBody',
                                tr: 'Şifre yok. Giriş ve kayıt için e-postana tek kullanımlık bir kod göndeririz.',
                                en: 'No password. We send a one-time code to your email to sign in or register.',
                              ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.x28),
                      if (!otpStep)
                        TextField(
                          key: const Key('auth-email'),
                          controller: _emailController,
                          enabled: !widget.viewModel.isBusy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: context.ota(
                              'authEmailLabel',
                              tr: 'E-posta',
                              en: 'Email',
                            ),
                            hintText: context.ota(
                              'authEmailHint',
                              tr: 'sen@ornek.com',
                              en: 'you@example.com',
                            ),
                          ),
                        )
                      else
                        TextField(
                          key: const Key('auth-otp'),
                          controller: _otpController,
                          enabled: !widget.viewModel.isBusy,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          textInputAction: TextInputAction.done,
                          onChanged: _onOtpChanged,
                          decoration: InputDecoration(
                            labelText: context.ota(
                              'authOtpLabel',
                              tr: '6 haneli kod',
                              en: '6-digit code',
                            ),
                            hintText: context.ota(
                              'authOtpHint',
                              tr: '000000',
                              en: '000000',
                            ),
                          ),
                        ),
                      if (widget.viewModel.errorMessage case final error?) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _localizedAuthError(
                              context,
                              widget.viewModel.errorCode,
                              error,
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        key: const Key('auth-submit'),
                        onPressed: widget.viewModel.isBusy ? null : _submit,
                        // The spinner replaces the label visually, so the
                        // action keeps its name for screen readers here.
                        child: widget.viewModel.isBusy
                            ? Semantics(
                                label: context.ota(
                                  'authSubmitBusySemantics',
                                  tr: '{action}, sürüyor',
                                  en: '{action}, in progress',
                                  replacements: {'action': actionLabel},
                                ),
                                excludeSemantics: true,
                                child: const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Text(actionLabel),
                      ),
                      if (otpStep) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            TextButton(
                              onPressed: widget.viewModel.isBusy
                                  ? null
                                  : widget.viewModel.editEmail,
                              child: Text(
                                context.ota(
                                  'authChangeEmailAction',
                                  tr: 'E-postayı değiştir',
                                  en: 'Change email',
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: widget.viewModel.canResend
                                  ? widget.viewModel.resendOtp
                                  : null,
                              child: Text(
                                widget.viewModel.canResend
                                    ? context.ota(
                                        'authResendCodeAction',
                                        tr: 'Kodu yeniden gönder',
                                        en: 'Resend code',
                                      )
                                    : context.ota(
                                        'secondsShort',
                                        tr: '{seconds} sn',
                                        en: '{seconds} sec',
                                        replacements: {
                                          'seconds':
                                              widget.viewModel.resendSeconds,
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        context.ota(
                          'authLegalNotice',
                          tr: 'Devam ederek Kullanım Koşulları ve Gizlilik Politikasını kabul edersin.',
                          en: 'By continuing, you agree to the Terms of Use and Privacy Policy.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _localizedAuthError(
  BuildContext context,
  AuthFailureCode? code,
  String fallback,
) {
  return switch (code) {
    AuthFailureCode.invalidEmail => context.ota(
      'authErrorInvalidEmail',
      tr: 'Geçerli bir e-posta adresi gir.',
      en: 'Enter a valid email address.',
    ),
    AuthFailureCode.invalidOtp => context.ota(
      'authErrorInvalidOtp',
      tr: 'Kod geçersiz. Kontrol edip tekrar dene.',
      en: 'The code is invalid. Check it and try again.',
    ),
    AuthFailureCode.expiredOtp => context.ota(
      'authErrorExpiredOtp',
      tr: 'Kodun süresi dolmuş. Yeni bir kod iste.',
      en: 'The code has expired. Request a new one.',
    ),
    AuthFailureCode.rateLimited => context.ota(
      'authErrorRateLimited',
      tr: 'Çok sık deneme yapıldı. Geri sayım bitince tekrar dene.',
      en: 'Too many attempts. Try again when the countdown ends.',
    ),
    AuthFailureCode.network => context.ota(
      'authErrorNetwork',
      tr: 'Bağlantı zaman aşımına uğradı. Tekrar dene.',
      en: 'The connection timed out. Try again.',
    ),
    AuthFailureCode.unknown || null => context.ota(
      'authErrorUnknown',
      tr: 'İşlem tamamlanamadı. Lütfen tekrar dene.',
      en: 'The operation could not be completed. Please try again.',
    ),
  };
}

/// Masks the local part of an address. Anything we cannot split — no `@`, an
/// empty local part — is hidden entirely rather than echoed back verbatim, and
/// a one-character local part is hidden too, since revealing its first
/// character would reveal all of it.
String _maskEmail(String email) {
  final separator = email.lastIndexOf('@');
  if (separator <= 0) return '•••';
  final domain = email.substring(separator + 1);
  if (separator == 1) return '•••@$domain';
  return '${email[0]}•••@$domain';
}
