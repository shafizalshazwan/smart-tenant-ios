const SHEET_NAME = 'Users';

function doPost(e) {
  try {
    const body = JSON.parse(e.postData.contents || '{}');
    const action = body.action;
    
    let res = { ok: false, message: 'Unknown action' };
    
    switch (action) {
      case 'signup':
        res = handleSignup(body);
        break;
      case 'verify':
        res = handleVerify(body);
        break;
      case 'resend':
        res = handleResend(body);
        break;
      case 'login':
        res = handleLogin(body);
        break;
      case 'forgot':
        res = handleForgot(body);
        break;
      case 'reset':
        res = handleReset(body);
        break;
      default:
        res = { ok: false, message: 'Invalid action' };
    }
    
    return ContentService
      .createTextOutput(JSON.stringify(res))
      .setMimeType(ContentService.MimeType.JSON);
      
  } catch (err) {
    const res = {
      ok: false,
      message: 'Server error: ' + err
    };
    return ContentService
      .createTextOutput(JSON.stringify(res))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

// ===== Helper functions =====

function getSheet() {
  return SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
}

function findUserRow(email) {
  const sheet = getSheet();
  const data = sheet.getDataRange().getValues(); // 2D array
  const target = (email || '').toString().toLowerCase();
  
  for (let i = 1; i < data.length; i++) { // skip header row
    const rowEmail = (data[i][0] || '').toString().toLowerCase();
    if (rowEmail === target) return i + 1; // sheet rows are 1-based
  }
  return -1;
}

function generateCode() {
  const n = Math.floor(Math.random() * 1000000);
  return ('000000' + n).slice(-6);
}

// ====== ACTION HANDLERS ======

function handleSignup(body) {
  const sheet = getSheet();
  const email = (body.email || '').toString().trim().toLowerCase();
  const password = (body.password || '').toString();
  const name = (body.name || '').toString();
  const phone = (body.phone || '').toString();
  const idNumber = (body.idNumber || '').toString();
  const emergency = (body.emergencyContact || '').toString();
  
  if (!email || !password) {
    return { ok: false, message: 'Email and password required' };
  }
  
  const row = findUserRow(email);
  if (row > 0) {
    return { ok: false, message: 'Email already registered' };
  }
  
  const code = generateCode();
  
  // Append new user
  sheet.appendRow([
    email,
    password,      // NOTE: For real system, hash the password!
    name,
    phone,
    idNumber,
    emergency,
    'tenant',      // default role
    false,         // isVerified
    code,
    ''             // resetToken
  ]);
  
  // Send verification email (optional – make sure MailApp is allowed)
  try {
    MailApp.sendEmail({
      to: email,
      subject: 'Smart Tenant - Email Verification Code',
      htmlBody: '<p>Your verification code is: <b>' + code + '</b></p>'
    });
  } catch (err) {
    // fail silently for demo
  }
  
  return { ok: true, message: 'Signup successful. Please check email for verification code.' };
}

function handleVerify(body) {
  const email = (body.email || '').toString().trim().toLowerCase();
  const code = (body.code || '').toString().trim();
  
  if (!email || !code) {
    return { ok: false, message: 'Email and code required' };
  }
  
  const sheet = getSheet();
  const row = findUserRow(email);
  if (row <= 0) {
    return { ok: false, message: 'Account not found' };
  }
  
  const values = sheet.getRange(row, 1, 1, 10).getValues()[0];
  const storedCode = (values[8] || '').toString().trim(); // verifyCode column (I)
  
  if (storedCode !== code) {
    return { ok: false, message: 'Invalid verification code' };
  }
  
  sheet.getRange(row, 8).setValue(true);   // isVerified (H)
  sheet.getRange(row, 9).setValue('');     // clear verifyCode (I)
  
  return { ok: true, message: 'Email verified', isVerified: true };
}

function handleResend(body) {
  const email = (body.email || '').toString().trim().toLowerCase();
  if (!email) {
    return { ok: false, message: 'Email required' };
  }
  
  const sheet = getSheet();
  const row = findUserRow(email);
  if (row <= 0) {
    // For security, we don't reveal if user exists
    return { ok: true, message: 'If the account exists, a new code was sent.' };
  }
  
  const code = generateCode();
  sheet.getRange(row, 9).setValue(code); // verifyCode (I)
  
  try {
    MailApp.sendEmail({
      to: email,
      subject: 'Smart Tenant - New Verification Code',
      htmlBody: '<p>Your new verification code is: <b>' + code + '</b></p>'
    });
  } catch (err) {}
  
  return { ok: true, message: 'Verification code resent (if account exists).' };
}

function handleLogin(body) {
  const email = (body.email || '').toString().trim().toLowerCase();
  const password = (body.password || '').toString();
  
  if (!email || !password) {
    return { ok: false, message: 'Email and password required' };
  }
  
  const sheet = getSheet();
  const row = findUserRow(email);
  if (row <= 0) {
    return { ok: false, message: 'Invalid email or password' };
  }
  
  const values = sheet.getRange(row, 1, 1, 10).getValues()[0];
  const storedPass = (values[1] || '').toString();
  const role = (values[6] || 'tenant').toString();
  const isVerified = !!values[7];
  
  if (storedPass !== password) {
    return { ok: false, message: 'Invalid email or password' };
  }
  
  if (!isVerified) {
    return { ok: false, message: 'Email not verified yet. Please verify your email.' };
  }
  
  return {
    ok: true,
    message: null,
    role: role,
    isVerified: isVerified
  };
}

function handleForgot(body) {
  const email = (body.email || '').toString().trim().toLowerCase();
  if (!email) {
    return { ok: false, message: 'Email required' };
  }
  
  const sheet = getSheet();
  const row = findUserRow(email);
  if (row <= 0) {
    // same trick: don't leak existence
    return { ok: true, message: 'If account exists, reset email sent.' };
  }
  
  const token = generateCode();
  sheet.getRange(row, 10).setValue(token); // resetToken (J)
  
  try {
    MailApp.sendEmail({
      to: email,
      subject: 'Smart Tenant - Password Reset Token',
      htmlBody: '<p>Your reset token is: <b>' + token + '</b></p>'
    });
  } catch (err) {}
  
  return { ok: true, message: 'If account exists, reset email sent.' };
}

function handleReset(body) {
  const email = (body.email || '').toString().trim().toLowerCase();
  const token = (body.token || '').toString().trim();
  const newPassword = (body.newPassword || '').toString();
  
  if (!email || !token || !newPassword) {
    return { ok: false, message: 'Email, token and new password required' };
  }
  
  const sheet = getSheet();
  const row = findUserRow(email);
  if (row <= 0) {
    return { ok: false, message: 'Invalid token or email' };
  }
  
  const values = sheet.getRange(row, 1, 1, 10).getValues()[0];
  const storedToken = (values[9] || '').toString().trim(); // resetToken (J)
  
  if (storedToken !== token) {
    return { ok: false, message: 'Invalid reset token' };
  }
  
  sheet.getRange(row, 2).setValue(newPassword); // password (B)
  sheet.getRange(row, 10).setValue('');         // clear resetToken
  
  return { ok: true, message: 'Password updated successfully' };
}
