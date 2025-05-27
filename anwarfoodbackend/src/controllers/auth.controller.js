const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');
const axios = require('axios');



async function sendVerificationOTP(phone) {
  const url = 'https://cpaas.messagecentral.com/verification/v3/send';

  const headers = {
    authToken: 'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJDLURFQkUyQjY4OTM4NTRBRCIsImlhdCI6MTcyMjMyNDU4MCwiZXhwIjoxODgwMDA0NTgwfQ.ihHWg1LXsk1WCjmYiCb0fA6sYrbqUORZjsw-0kr90w662ZlW7UCbb_O5GWx9_7gnzWdTA3zoGgmc1p2tQ2B4mg'
  };

  const params = {
    countryCode: '91',
    customerId: 'C-DEBE2B6893854AD',
    flowType: 'SMS',
    mobileNumber: phone
  };

  try {
    const response = await axios.post(url, null, {
      headers: headers,
      params: params
    });

    if (response.status !== 200) {
      throw new Error("Please wait 60 seconds before trying again.");
    }

    return response.data;
  } catch (error) {
    console.error("Error sending OTP:", error.message);
    return false;
  }
}


async function validateOTP(phone, verification_code, otp) {
  const url = 'https://cpaas.messagecentral.com/verification/v3/validateOtp';

  const headers = {
    authToken: 'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJDLUZBNTY5QzEzODY0QjQ5OSIsImlhdCI6MTcyMDY3NzcwOSwiZXhwIjoxODc4MzU3NzA5fQ.IKzKR57hg8vdCQux-GnGbuxw1H9BMXxrrJOS_OwUl2TZ2XxDZpDof9wcvenw6yG2Ygjcpfr8dEMVizPZaWf-KA'
  };

  const params = {
    countryCode: '91',
    mobileNumber: phone,
    verificationId: verification_code,
    customerId: 'C-DEBE2B6893854AD',
    code: otp
  };

  try {
    const response = await axios.get(url, {
      headers: headers,
      params: params
    });

    if (response.status !== 200) {
      throw new Error("The OTP is either invalid or has expired.");
    }

    const verificationStatus = response.data?.data?.verificationStatus;
    return verificationStatus === 'VERIFICATION_COMPLETED';
  } catch (error) {
    console.error("Error validating OTP:", error.message);
    throw error;
  }
}



const signup = async (req, res) => {
  try {
    const { username, email, password, mobile, city, province, zip, address } = req.body;

    // Check if user already exists in user_info table only
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE EMAIL = ? OR MOBILE = ?',
      [email, mobile]
    );

    if (existingUser.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email or mobile'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert new user with UL_ID set to 1 (assuming 1 is a valid user level ID)
    const [result] = await db.promise().query(
      `INSERT INTO user_info (
        UL_ID, USERNAME, EMAIL, MOBILE, PASSWORD, CITY, PROVINCE, ZIP, ADDRESS, 
        CREATED_DATE, USER_TYPE, ISACTIVE
      ) VALUES (
        1, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), 'customer', 'Y'
      )`,
      [username, email, mobile, hashedPassword, city, province, zip, address]
    );

    let dataCode;
    try {
      dataCode = await sendVerificationOTP(mobile);
      console.log(dataCode);
      
      if (dataCode == false) {
        return res.status(500).json({
          success: false,
          message: 'Please wait 60 seconds before trying again.',
          error: "Please wait 60 seconds before trying again."
        });
      }
      
      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        userId: result.insertId,
        verificationId: dataCode?.data?.verificationId || null
      });
    } catch (err) {
      console.log('Error:', err.message);
      return res.status(500).json({
        success: false,
        message: 'Please wait 60 seconds before trying again.',
        error: "Please wait 60 seconds before trying again."
      });
    }
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in registration',
      error: error.message
    });
  }
};

const login = async (req, res) => {
  try {
    const { phone, password } = req.body;

    // Find user
    const [users] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?' ,
      [phone]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Login failed. Make sure your Phone and password are correct.'
      });
    }

    const user = users[0];

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.PASSWORD);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Login failed. Make sure your email and password are correct.'
      });
    }
    console.log(user['is_otp_verify']);
    if (user['is_otp_verify'] != 1) {
      let dataCode;
      try {
        dataCode = await sendVerificationOTP(phone);
        console.log(dataCode);
      } catch (err) {
        console.log('Error:', err.message);
        return res.status(401).json({
          success: false,
          message: 'You need to verify your account, Please contact support',
          verificationId: null,
          userId: user.USER_ID
        });
      }
      
      return res.status(401).json({
        success: false,
        message: 'You need to verify your account, Please contact support',
        verificationId: dataCode?.data?.verificationId || null,
        userId: user.USER_ID
      });
    }

    // Generate token
    const token = jwt.sign(
      { userId: user.USER_ID, email: user.EMAIL },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '100h' }
    );

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user.USER_ID,
        username: user.USERNAME,
        email: user.EMAIL,
        mobile: user.MOBILE
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in login',
      error: error.message
    });
  }
};

const verifyOtp = async (req, res) => {
  try {
    const { phone, verification_code, otp } = req.body;

    const isOTPValid = await validateOTP(phone, verification_code, otp);
    if (!isOTPValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?',
      [phone]
    );

    const user = existingUser[0];

    // Update is_otp_verify field to true
    await db.promise().query(
      'UPDATE user_info SET is_otp_verify = TRUE WHERE MOBILE = ?',
      [phone]
    );

    res.json({
      success: true,
      message: 'Account verified successfully please login',
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in login',
      error: error.message
    });
  }
};

const resetPassword = async (req, res) => {
  try {
    const { phone } = req.body;

    // Check if user exists with this phone number
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?',
      [phone]
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No user found with this phone number'
      });
    }

    // Send OTP for password reset
    let dataCode;
    await sendVerificationOTP(phone)
      .then(data => {
        console.log(data);
        dataCode = data;
      })
      .catch(err => {
        console.log('Error:', err.message);
        throw new Error('Failed to send OTP');
      });

    res.json({
      success: true,
      message: 'OTP sent successfully for password reset',
      verificationId: dataCode.verificationId || null
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in sending OTP for password reset',
      error: error.message
    });
  }
};

const verifyOtpPassword = async (req, res) => {
  try {
    const { phone, verification_code, otp } = req.body;

    // Check if user exists with this phone number
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?',
      [phone]
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No user found with this phone number'
      });
    }

    // Validate OTP
    const isOTPValid = await validateOTP(phone, verification_code, otp);
    if (!isOTPValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    res.json({
      success: true,
      message: 'OTP verified successfully. You can now change your password.',
    });
  } catch (error) {
    console.error('Verify OTP password error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in verifying OTP',
      error: error.message
    });
  }
};

const changePassword = async (req, res) => {
  try {
    const { phone, password, confirmPassword } = req.body;

    // Check if passwords match
    if (password !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'Password and confirm password do not match'
      });
    }

    // Check if user exists with this phone number
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?',
      [phone]
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No user found with this phone number'
      });
    }

    // Hash the new password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Update the password in database
    await db.promise().query(
      'UPDATE user_info SET PASSWORD = ? WHERE MOBILE = ?',
      [hashedPassword, phone]
    );

    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in changing password',
      error: error.message
    });
  }
};

module.exports = {
  signup,
  login,
  verifyOtp,
  resetPassword,
  verifyOtpPassword,
  changePassword
}; 