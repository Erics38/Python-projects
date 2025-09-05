#!/usr/bin/env node

// Test script to verify Parameter Store integration
const AWS = require('aws-sdk');

AWS.config.update({ region: 'us-east-1' });
const ssm = new AWS.SSM();

async function getParameter(name) {
  try {
    const result = await ssm.getParameter({
      Name: name,
      WithDecryption: true
    }).promise();
    return result.Parameter.Value;
  } catch (error) {
    console.error(`❌ Failed to get parameter ${name}:`, error.message);
    return null;
  }
}

async function testParameterStore() {
  console.log('🧪 Testing Parameter Store Integration...\n');
  
  const parameters = [
    '/guestbook/db/host',
    '/guestbook/db/name', 
    '/guestbook/db/user',
    '/guestbook/db/password',
    '/guestbook/db/port',
    '/guestbook/aws/region',
    '/guestbook/sqs/queue-url',
    '/guestbook/ses/from-email',
    '/guestbook/ses/to-email'
  ];
  
  let successCount = 0;
  
  for (const paramName of parameters) {
    const value = await getParameter(paramName);
    if (value) {
      console.log(`✅ ${paramName}: ${paramName.includes('password') ? '***hidden***' : value}`);
      successCount++;
    } else {
      console.log(`❌ ${paramName}: FAILED`);
    }
  }
  
  console.log(`\n📊 Results: ${successCount}/${parameters.length} parameters loaded successfully`);
  
  if (successCount === parameters.length) {
    console.log('🎉 All parameters loaded! Your application should work correctly.');
  } else {
    console.log('⚠️  Some parameters are missing. Run setup-parameters.sh first.');
  }
}

async function testDatabaseConfig() {
  console.log('\n🗄️  Testing Database Configuration...');
  
  try {
    const config = {
      dbHost: await getParameter('/guestbook/db/host'),
      dbName: await getParameter('/guestbook/db/name'),
      dbUser: await getParameter('/guestbook/db/user'),
      dbPassword: await getParameter('/guestbook/db/password'),
      dbPort: await getParameter('/guestbook/db/port')
    };
    
    if (Object.values(config).every(v => v !== null)) {
      console.log('✅ Database configuration complete');
      console.log(`   Host: ${config.dbHost}:${config.dbPort}`);
      console.log(`   Database: ${config.dbName}`);
      console.log(`   User: ${config.dbUser}`);
    } else {
      console.log('❌ Database configuration incomplete');
    }
  } catch (error) {
    console.error('❌ Database configuration test failed:', error.message);
  }
}

async function testAWSConfig() {
  console.log('\n☁️  Testing AWS Configuration...');
  
  try {
    const queueUrl = await getParameter('/guestbook/sqs/queue-url');
    const fromEmail = await getParameter('/guestbook/ses/from-email');
    const toEmail = await getParameter('/guestbook/ses/to-email');
    
    if (queueUrl && fromEmail && toEmail) {
      console.log('✅ AWS services configuration complete');
      console.log(`   SQS Queue: ${queueUrl.split('/').pop()}`);
      console.log(`   From Email: ${fromEmail}`);
      console.log(`   To Email: ${toEmail}`);
    } else {
      console.log('❌ AWS services configuration incomplete');
    }
  } catch (error) {
    console.error('❌ AWS configuration test failed:', error.message);
  }
}

// Run all tests
testParameterStore()
  .then(() => testDatabaseConfig())
  .then(() => testAWSConfig())
  .then(() => {
    console.log('\n✨ Testing complete! Check the results above.');
    console.log('\nNext steps:');
    console.log('1. If parameters are missing, run: bash setup-parameters.sh');
    console.log('2. Ensure your AWS credentials have SSM permissions');
    console.log('3. Start your application: docker-compose up -d');
  })
  .catch((error) => {
    console.error('🚨 Test failed:', error);
    process.exit(1);
  });