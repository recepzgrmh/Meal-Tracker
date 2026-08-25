export type EmailActionType =
  | 'signup'
  | 'magiclink'
  | 'recovery'
  | 'invite'
  | 'email_change'
  | 'reauthentication'

export interface SendEmailHookPayload {
  user: {
    id: string
    email: string
    new_email?: string
  }
  email_data: {
    token: string
    token_hash: string
    token_new?: string
    token_hash_new?: string
    email_action_type: EmailActionType | string
    redirect_to?: string
    site_url?: string
  }
}

export interface EmailDelivery {
  to: string
  subject: string
  text: string
  html: string
}

const actionCopy: Record<string, { subject: string; eyebrow: string; description: string }> = {
  signup: {
    subject: 'Meal Clarity doğrulama kodun',
    eyebrow: 'HESABINI DOĞRULA',
    description: 'Meal Clarity hesabını oluşturmak için aşağıdaki tek kullanımlık kodu gir.',
  },
  magiclink: {
    subject: 'Meal Clarity giriş kodun',
    eyebrow: 'GÜVENLİ GİRİŞ',
    description: 'Meal Clarity hesabına giriş yapmak için aşağıdaki tek kullanımlık kodu gir.',
  },
  recovery: {
    subject: 'Meal Clarity hesap kurtarma kodun',
    eyebrow: 'HESAP KURTARMA',
    description: 'Hesabına yeniden erişmek için aşağıdaki tek kullanımlık kodu gir.',
  },
  invite: {
    subject: "Meal Clarity'ye davet edildin",
    eyebrow: 'DAVETİN VAR',
    description: 'Meal Clarity davetini kabul etmek için aşağıdaki tek kullanımlık kodu gir.',
  },
  email_change: {
    subject: 'Yeni e-posta adresini doğrula',
    eyebrow: 'E-POSTA DEĞİŞİKLİĞİ',
    description: 'E-posta adresi değişikliğini doğrulamak için aşağıdaki tek kullanımlık kodu gir.',
  },
  reauthentication: {
    subject: 'Meal Clarity güvenlik kodun',
    eyebrow: 'GÜVENLİK KONTROLÜ',
    description: 'Bu hassas işlemi tamamlamak için aşağıdaki tek kullanımlık kodu gir.',
  },
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;')
}

function renderCode(code: string): string {
  return code.split('').map(escapeHtml).join('&nbsp;')
}

export function renderAuthEmail(action: string, token: string): Omit<EmailDelivery, 'to'> {
  const copy = actionCopy[action] ?? actionCopy.magiclink
  const safeToken = escapeHtml(token)

  return {
    subject: copy.subject,
    text:
      `${copy.description}\n\nKodun: ${token}\n\nBu kodu kimseyle paylaşma. Bu isteği sen yapmadıysan e-postayı yok sayabilirsin.`,
    html: `<!doctype html>
<html lang="tr">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${escapeHtml(copy.subject)}</title>
  </head>
  <body style="margin:0;background:#f5f6f2;font-family:Inter,-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;color:#11140f">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f5f6f2;padding:40px 16px">
      <tr><td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;background:#ffffff;border:1px solid #e7e9e1;border-radius:24px;overflow:hidden">
          <tr><td style="height:8px;background:#b7e51c"></td></tr>
          <tr><td style="padding:40px 40px 16px">
            <div style="font-size:22px;font-weight:800;letter-spacing:-0.5px">Meal Clarity<span style="color:#8ab900">.</span></div>
          </td></tr>
          <tr><td style="padding:20px 40px 8px;color:#789b0d;font-size:12px;font-weight:800;letter-spacing:1.4px">${
      escapeHtml(copy.eyebrow)
    }</td></tr>
          <tr><td style="padding:0 40px;font-size:28px;font-weight:800;line-height:1.2">${
      escapeHtml(copy.subject)
    }</td></tr>
          <tr><td style="padding:14px 40px 0;color:#62675d;font-size:16px;line-height:1.6">${
      escapeHtml(copy.description)
    }</td></tr>
          <tr><td style="padding:28px 40px">
            <div aria-label="Doğrulama kodu ${safeToken}" style="padding:22px 16px;border-radius:16px;background:#f1f8d9;color:#182000;text-align:center;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:34px;font-weight:800;letter-spacing:4px">${
      renderCode(token)
    }</div>
          </td></tr>
          <tr><td style="padding:0 40px 40px;color:#858a80;font-size:13px;line-height:1.6">Bu kodu kimseyle paylaşma. Bu isteği sen yapmadıysan e-postayı güvenle yok sayabilirsin.</td></tr>
        </table>
      </td></tr>
    </table>
  </body>
</html>`,
  }
}

export function buildEmailDeliveries(payload: SendEmailHookPayload): EmailDelivery[] {
  const { user, email_data: email } = payload
  const action = email.email_action_type

  if (action === 'email_change' && email.token_new && user.new_email) {
    const deliveries: EmailDelivery[] = []

    if (email.token) {
      deliveries.push({ to: user.email, ...renderAuthEmail(action, email.token) })
    }
    deliveries.push({ to: user.new_email, ...renderAuthEmail(action, email.token_new) })
    return deliveries
  }

  if (!user.email || !email.token) {
    throw new Error('Hook payload does not contain a recipient and token')
  }

  return [{ to: user.email, ...renderAuthEmail(action, email.token) }]
}
