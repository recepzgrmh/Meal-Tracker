import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
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
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                      const SizedBox(height: 28),
                      Text(
                        otpStep
                            ? 'E-postandaki kodu gir.'
                            : 'İlerlemeni cihazların arasında koru.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        otpStep
                            ? 'Altı haneli kodu ${_maskEmail(widget.viewModel.email)} adresine gönderdik.'
                            : 'Şifre yok. Giriş ve kayıt için e-postana tek kullanımlık bir kod göndeririz.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      if (!otpStep)
                        TextField(
                          key: const Key('auth-email'),
                          controller: _emailController,
                          enabled: !widget.viewModel.isBusy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'E-posta',
                            hintText: 'sen@ornek.com',
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
                          onChanged: (value) {
                            if (value.length == 6) _submit();
                          },
                          decoration: const InputDecoration(
                            labelText: '6 haneli kod',
                            hintText: '000000',
                          ),
                        ),
                      if (widget.viewModel.errorMessage case final error?) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            error,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        key: const Key('auth-submit'),
                        onPressed: widget.viewModel.isBusy ? null : _submit,
                        child: widget.viewModel.isBusy
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(otpStep ? 'Kodu doğrula' : 'Kod gönder'),
                      ),
                      if (otpStep) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            TextButton(
                              onPressed: widget.viewModel.isBusy
                                  ? null
                                  : widget.viewModel.editEmail,
                              child: const Text('E-postayı değiştir'),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: widget.viewModel.canResend
                                  ? widget.viewModel.resendOtp
                                  : null,
                              child: Text(
                                widget.viewModel.canResend
                                    ? 'Kodu yeniden gönder'
                                    : '${widget.viewModel.resendSeconds} sn',
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Devam ederek Kullanım Koşulları ve Gizlilik Politikasını kabul edersin.',
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

String _maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2 || parts.first.isEmpty) return email;
  final visible = parts.first.substring(0, 1);
  return '$visible•••@${parts.last}';
}
