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

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
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

  void _editEmail() {
    _otpController.clear();
    widget.viewModel.editEmail();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final otpStep = widget.viewModel.step == AuthStep.otp;
        final coolingDown = widget.viewModel.resendSeconds > 0;
        final canSubmit = otpStep
            ? !widget.viewModel.isBusy && _otpController.text.length == 6
            : widget.viewModel.canRequestOtp;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _AuthHeader(onBack: otpStep ? _editEmail : null),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xxl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : AppMotion.standard,
                          child: otpStep
                              ? _OtpForm(
                                  key: const ValueKey('otp-form'),
                                  viewModel: widget.viewModel,
                                  controller: _otpController,
                                  canSubmit: canSubmit,
                                  onChanged: (_) {
                                    widget.viewModel.clearError();
                                    setState(() {});
                                  },
                                  onSubmit: _submit,
                                  onEditEmail: _editEmail,
                                )
                              : _EmailForm(
                                  key: const ValueKey('email-form'),
                                  viewModel: widget.viewModel,
                                  controller: _emailController,
                                  canSubmit: canSubmit,
                                  coolingDown: coolingDown,
                                  onChanged: (_) {
                                    widget.viewModel.clearError();
                                    setState(() {});
                                  },
                                  onSubmit: _submit,
                                  onUseExistingCode:
                                      widget.viewModel.useExistingCode,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppTouchTarget.minimum,
            height: AppTouchTarget.minimum,
            child: onBack == null
                ? null
                : IconButton(
                    tooltip: context.ota('commonBack', tr: 'Geri', en: 'Back'),
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
          ),
          Expanded(
            child: Text(
              'Meal Clarity',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(
            width: AppTouchTarget.minimum,
            height: AppTouchTarget.minimum,
          ),
        ],
      ),
    );
  }
}

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.viewModel,
    required this.controller,
    required this.canSubmit,
    required this.coolingDown,
    required this.onChanged,
    required this.onSubmit,
    required this.onUseExistingCode,
    super.key,
  });

  final AuthViewModel viewModel;
  final TextEditingController controller;
  final bool canSubmit;
  final bool coolingDown;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onUseExistingCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.ota(
            'authEmailTitle',
            tr: 'E-postanla devam et.',
            en: 'Continue with your email.',
          ),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.ota(
            'authEmailBody',
            tr: 'Şifre yok. Sana tek kullanımlık 6 haneli bir kod göndereceğiz.',
            en: 'No password. We will send you a one-time six-digit code.',
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.x28),
        TextField(
          key: const Key('auth-email'),
          controller: controller,
          enabled: !viewModel.isBusy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          onSubmitted: canSubmit ? (_) => onSubmit() : null,
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
        ),
        if (viewModel.errorMessage case final error?) ...[
          const SizedBox(height: AppSpacing.sm),
          _AuthErrorPanel(
            code: viewModel.errorCode,
            fallback: error,
            seconds: viewModel.resendSeconds,
            onUseExistingCode: viewModel.isEmailRateLimited
                ? onUseExistingCode
                : null,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const Key('auth-submit'),
          onPressed: canSubmit ? onSubmit : null,
          child: viewModel.isBusy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  coolingDown
                      ? context.ota(
                          'authRetryCountdown',
                          tr: '{time} sonra tekrar dene',
                          en: 'Try again in {time}',
                          replacements: {
                            'time': _formatCountdown(viewModel.resendSeconds),
                          },
                        )
                      : context.ota(
                          'authSendCodeAction',
                          tr: 'Kod gönder',
                          en: 'Send code',
                        ),
                ),
        ),
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
    );
  }
}

class _OtpForm extends StatelessWidget {
  const _OtpForm({
    required this.viewModel,
    required this.controller,
    required this.canSubmit,
    required this.onChanged,
    required this.onSubmit,
    required this.onEditEmail,
    super.key,
  });

  final AuthViewModel viewModel;
  final TextEditingController controller;
  final bool canSubmit;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onEditEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.ota(
            'authOtpTitle',
            tr: 'Kodunu kontrol et.',
            en: 'Check your code.',
          ),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.ota(
            'authOtpBody',
            tr: '6 haneli kodu {email} adresine gönderdik.',
            en: 'We sent a six-digit code to {email}.',
            replacements: {'email': _maskEmail(viewModel.email)},
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.x28),
        TextField(
          key: const Key('auth-otp'),
          controller: controller,
          enabled: !viewModel.isBusy,
          autofocus: true,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            letterSpacing: 8,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          onChanged: onChanged,
          onSubmitted: canSubmit ? (_) => onSubmit() : null,
          decoration: InputDecoration(
            labelText: context.ota(
              'authOtpLabel',
              tr: '6 haneli kod',
              en: '6-digit code',
            ),
            hintText: '000000',
          ),
        ),
        if (viewModel.errorMessage case final error?) ...[
          const SizedBox(height: AppSpacing.sm),
          _AuthErrorPanel(
            code: viewModel.errorCode,
            fallback: error,
            seconds: viewModel.resendSeconds,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const Key('auth-submit'),
          onPressed: canSubmit ? onSubmit : null,
          child: viewModel.isBusy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  context.ota(
                    'authVerifyCodeAction',
                    tr: 'Kodu doğrula',
                    en: 'Verify code',
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton(
              onPressed: viewModel.isBusy ? null : onEditEmail,
              child: Text(
                context.ota(
                  'authChangeEmailAction',
                  tr: 'E-postayı değiştir',
                  en: 'Change email',
                ),
              ),
            ),
            TextButton(
              onPressed: viewModel.canResend ? viewModel.resendOtp : null,
              child: Text(
                viewModel.canResend
                    ? context.ota(
                        'authResendCodeAction',
                        tr: 'Yeniden gönder',
                        en: 'Resend',
                      )
                    : _formatCountdown(viewModel.resendSeconds),
              ),
            ),
          ],
        ),
        Text(
          context.ota(
            'authSpamHint',
            tr: 'Kod görünmüyorsa spam klasörünü de kontrol et.',
            en: 'If you cannot see the code, check your spam folder too.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AuthErrorPanel extends StatelessWidget {
  const _AuthErrorPanel({
    required this.code,
    required this.fallback,
    required this.seconds,
    this.onUseExistingCode,
  });

  final AuthFailureCode? code;
  final String fallback;
  final int seconds;
  final VoidCallback? onUseExistingCode;

  @override
  Widget build(BuildContext context) {
    final emailLimit = code == AuthFailureCode.emailRateLimited;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.reviewSurface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 20,
                  color: AppColors.reviewInk,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    emailLimit
                        ? context.ota(
                            'authErrorEmailLimit',
                            tr: 'E-posta gönderim sınırına ulaşıldı. Daha önce gelen kod hâlâ geçerliyse onu kullanabilirsin.',
                            en: 'The email sending limit was reached. If your previous code is still valid, you can use it.',
                          )
                        : _localizedAuthError(context, code, fallback),
                    style: const TextStyle(color: AppColors.reviewInk),
                  ),
                ),
              ],
            ),
            if (seconds > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.ota(
                  'authLimitCountdownDetail',
                  tr: 'Yeni istek: yaklaşık {time} sonra',
                  en: 'New request: in about {time}',
                  replacements: {'time': _formatCountdown(seconds)},
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.reviewInk),
              ),
            ],
            if (onUseExistingCode != null) ...[
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                key: const Key('auth-use-existing-code'),
                onPressed: onUseExistingCode,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.reviewInk,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  context.ota(
                    'authUseExistingCode',
                    tr: 'Daha önce gelen kodu kullan',
                    en: 'Use the code already sent',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
    AuthFailureCode.emailDeliveryFailed => context.ota(
      'authErrorEmailDelivery',
      tr: 'Doğrulama e-postası şu anda gönderilemedi. Biraz sonra tekrar dene.',
      en: 'The verification email could not be sent right now. Please try again shortly.',
    ),
    AuthFailureCode.emailRateLimited ||
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

String _formatCountdown(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}

String _maskEmail(String email) {
  final separator = email.lastIndexOf('@');
  if (separator <= 0) return '•••';
  final domain = email.substring(separator + 1);
  if (separator == 1) return '•••@$domain';
  return '${email[0]}•••@$domain';
}
