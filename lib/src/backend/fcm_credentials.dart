/// Firebase Service Account credentials for server-authorized FCM HTTP v1 dispatching.
///
/// These credentials allow Smart Meet to send push notifications via Firebase Cloud Messaging
/// (FCM v1 API) directly to recipient device tokens and topics.
class FcmCredentials {
  static const String projectId = 'smart-meet-779bc';
  static const String clientEmail =
      'firebase-adminsdk-fbsvc@smart-meet-779bc.iam.gserviceaccount.com';

  static const Map<String, dynamic> serviceAccountMap = {
    'type': 'service_account',
    'project_id': projectId,
    'private_key_id': '99a771807bd173aa0e5e728e183ed136292d23e5',
    'private_key':
        '-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC9GdETakSBcGzj\nvo7JNE52ChfDkvz1YD5pvXFjSJy2kaKuEltZ9zdD2sr5nnANJczenhg8BrfwPF4e\npFvo5LlfNC6MWpPC0vr9abI305YSVIG4nJnEvdbZcAbOlTVco52HcJP2p6YcCLuc\n9rsrBAowThJBtEI6jQNZ4Ks/v5w8GH1G/MzKF78KeOg9bdoweCbbcdCPJDXpWnyY\neru7DCaiM7QLKYx6cR++zy6beoNbJgUok9jAFS1bXQb78uqHlMUxFu+85gaNkTLR\n6oXS1HKSPzDljaX8/bOivvF19aaTcpCN1UHkkB3SUZNlitsqd8C7nZ436ruEUWAM\n8BaFJwSZAgMBAAECggEAQ6DOAxGIOnqIltJ5oj+Qp+poIUuaJ+8powtbV9SKJ0ji\nUzrBbOVa4GuJF8iv7iPMpvkHVcBZXBNa3b6OGDZkjUXON+fU3GIz3RlF4W1MSHXs\nhqeK3q+9/Llx1cPK97yUA/IhGJ9Qaso8vqAGxBWHx0rEgLcE0IfJ4QTWec//AgZq\njRqiFrj4xd+ye3XzMo25gViJ+TWE1N1Zme2vTVP19CGeJzAq+Q4aenHeS6I+PqA7\nlr5NtTWi6JIxkYxUaQsGTu/HuIkSyMvB8kIG79lwF7bwzYi2QYSi4ZFIIdhIfKvp\n2M8OsKC8jlQqQdGrys3TF5ea+ZMRZbeNwyiPA2XG2QKBgQDmTs6u5AaPN36P/IGy\nz+3gOnObOgnAkA15wNTb1z+h93I6vypfB+Jzu0GaxfeVIcJ/VSVjcWkFs5uKXyCs\nbA8xOyaWsRHoLwVKse1j91qAvCcNNUyByQEWafg6Lq85oXGif0tCv6sw/KE6skYL\n2fZbMF6Qm1s2zsLr83x5061G/wKBgQDSMjWCWTMpPVXe77hrANl8F+p9ZsJx6j1S\nRzes9VkvZ85QxA178dBSI1r6B54g9dbW50SOCoB2wNfxF5zETrBKsYUPfbgTxqc5\n/9VcjktZpwHfs7ur7Dd1uVp0v50q/DkAAWDpdKJfa9e0XIuil8SBVkPPJOpyrbnB\nd1ZcJGSMZwKBgHYRpMfoQqydaJbsfplrG6o+jRHhOSqtLxtiDj3+JbMlJjyT0GcT\npbZrI4DzSK/9tLaOsjI+6/ZuU6kmh5udclRs3KWYdXOw12epu+fp4U3qJ6MP1f8b\nSyFwhj9du5sx9w21cKHxnRPqD8YFqv9caH3rWC+OVb7NVQSduQzDxiuFAoGBALoI\nTAmAjuI58c0s10iE6PeGZzfzgba2fO1cMK94OiXVtukOi2yeOSTpO7S8lzxOuIVd\nC/S24Lm5taUgo9OuXSLOeJicSRXfpNOVVK3lFlVTlTn65eekWfVsRd28VQrdTklt\n7urQGoFfffqYSdFuhzF9OuiToJg8n4HV7+3/G6qTAoGAWZEngObgue8swbXC6eS0\ntwd6ZAU/iCj9aN7YnoidtNNs4bQ0sAC15Ki9FZdTOr1lM2TePPc0ezl5TM5k+pAM\nw9mePxhUZg2jYExlSxePBRuSgVx5pHRKF9VdvzHB6qzEyAqiFn+daz1F5AOBj+kI\nDpFndEcpY81fBeQ31FHZVb4=\n-----END PRIVATE KEY-----\n',
    'client_email': clientEmail,
    'client_id': '108295820129042762230',
    'auth_uri': 'https://accounts.google.com/o/oauth2/auth',
    'token_uri': 'https://oauth2.googleapis.com/token',
    'auth_provider_x509_cert_url': 'https://www.googleapis.com/oauth2/v1/certs',
    'client_x509_cert_url':
        'https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40smart-meet-779bc.iam.gserviceaccount.com',
    'universe_domain': 'googleapis.com',
  };
}

