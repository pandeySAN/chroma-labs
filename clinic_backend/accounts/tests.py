from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase
from rest_framework import status

User = get_user_model()


class UserModelTests(TestCase):
    """Tests for the custom User model."""
    
    def test_create_user_with_email(self):
        """Test creating a user with an email is successful."""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User',
        )
        
        self.assertEqual(user.email, 'test@example.com')
        self.assertEqual(user.auth_provider, 'email')
        self.assertTrue(user.check_password('testpass123'))
    
    def test_user_full_name_property(self):
        """Test the full_name property."""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123',
            first_name='John',
            last_name='Doe',
        )
        
        self.assertEqual(user.full_name, 'John Doe')
    
    def test_user_str_returns_email(self):
        """Test the string representation of a user."""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User',
        )
        
        self.assertEqual(str(user), 'test@example.com')


class UserRegistrationAPITests(APITestCase):
    """Tests for user registration API."""
    
    def test_user_registration_success(self):
        """Test successful user registration."""
        payload = {
            'email': 'newuser@example.com',
            'username': 'newuser',
            'password': 'TestPass123!',
            'password_confirm': 'TestPass123!',
            'first_name': 'Test',
            'last_name': 'User',
        }
        
        response = self.client.post('/api/accounts/register/', payload)
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('tokens', response.data)
        self.assertIn('access', response.data['tokens'])
        self.assertIn('refresh', response.data['tokens'])
    
    def test_user_registration_password_mismatch(self):
        """Test registration fails with mismatched passwords."""
        payload = {
            'email': 'newuser@example.com',
            'username': 'newuser',
            'password': 'TestPass123!',
            'password_confirm': 'DifferentPass123!',
            'first_name': 'Test',
            'last_name': 'User',
        }
        
        response = self.client.post('/api/accounts/register/', payload)
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
