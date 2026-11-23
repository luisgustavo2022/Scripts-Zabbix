cat > kinghost_monitor.py << 'EOF'
#!/usr/bin/env python3
import imaplib
import email
from email.header import decode_header
import re
import sys

def check_kinghost_alert():
    IMAP_SERVER = ''
    EMAIL_ACCOUNT = ''
    EMAIL_PASSWORD = ''
    
    try:
        print(f"DEBUG: Conectando ao {IMAP_SERVER}...", file=sys.stderr)
        mail = imaplib.IMAP4_SSL(IMAP_SERVER)
        mail.login(EMAIL_ACCOUNT, EMAIL_PASSWORD)
        mail.select('inbox')
        print("DEBUG: Conectado com sucesso!", file=sys.stderr)
        
        result, data = mail.search(None, '(FROM "nao-responda@kinghost.com.br")')
        email_ids = data[0].split()
        
        print(f"DEBUG: Encontrados {len(email_ids)} emails da KingHost", file=sys.stderr)
        
        for email_id in email_ids[-10:]:
            result, data = mail.fetch(email_id, '(RFC822)')
            raw_email = data[0][1]
            msg = email.message_from_bytes(raw_email)
            
            subject = decode_header(msg['subject'])[0][0]
            if isinstance(subject, bytes):
                subject = subject.decode()
            
            print(f"DEBUG: Verificando assunto: {subject}", file=sys.stderr)
            
            if subject and "Atenção: risco do seu email ser bloqueado" in subject:
                print(f"DEBUG: ✅ Email de alerta encontrado!", file=sys.stderr)
                
                body = ""
                if msg.is_multipart():
                    for part in msg.walk():
                        content_type = part.get_content_type()
                        content_disposition = str(part.get("Content-Disposition"))
                        if content_type == "text/plain" and "attachment" not in content_disposition:
                            body = part.get_payload(decode=True).decode()
                            break
                else:
                    body = msg.get_payload(decode=True).decode()
                
                metrics = {
                    'alert_detected': 1,
                    'emails_sent': 0,
                    'limit_emails': 400,
                    'usage_percent': 0,
                    'recipients_count': 0,
                    'limit_recipients': 1000,
                    'main_account': 'pagadoria@gruppordf.com'
                }
                
                if body:
                    print(f"DEBUG: Extraindo dados do corpo...", file=sys.stderr)
                    
                    emails_match = re.search(r'Número de envios desta conta → (\d+)', body)
                    if emails_match:
                        metrics['emails_sent'] = int(emails_match.group(1))
                    
                    limit_match = re.search(r'Limite de envios.*?→ (\d+)', body)
                    if limit_match:
                        metrics['limit_emails'] = int(limit_match.group(1))
                    
                    recipients_match = re.search(r'Destinatários que receberam os emails → (\d+)', body)
                    if recipients_match:
                        metrics['recipients_count'] = int(recipients_match.group(1))
                    
                    account_match = re.search(r'Conta que enviou mais emails → (.+)', body)
                    if account_match:
                        metrics['main_account'] = account_match.group(1).strip()
                    
                    if metrics['emails_sent'] > 0 and metrics['limit_emails'] > 0:
                        metrics['usage_percent'] = int((metrics['emails_sent'] / metrics['limit_emails']) * 100)
                
                print(f"alert_detected:{metrics['alert_detected']}")
                print(f"emails_sent:{metrics['emails_sent']}")
                print(f"limit_emails:{metrics['limit_emails']}")
                print(f"usage_percent:{metrics['usage_percent']}")
                print(f"recipients_count:{metrics['recipients_count']}")
                print(f"limit_recipients:{metrics['limit_recipients']}")
                print(f"main_account:{metrics['main_account']}")
                
                mail.logout()
                return
        
        print("DEBUG: ❌ Nenhum alerta específico encontrado", file=sys.stderr)
        print("alert_detected:0")
        print("emails_sent:0")
        print("usage_percent:0")
        print("main_account:none")
        
        mail.logout()
        
    except Exception as e:
        print(f"DEBUG: ❌ Erro: {str(e)}", file=sys.stderr)
        print(f"error:1")
        print(f"error_message:{str(e)}")

if __name__ == "__main__":
    check_kinghost_alert()
EOF
