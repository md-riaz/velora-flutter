# API Client

`Velora.api` is a `GetxService` around Dio. It applies the configured base URL, injects the stored bearer token, returns `ApiResponse<T>`, and normalizes Laravel validation/API errors into `ApiException`.

```dart
await Velora.api.get('/users');
await Velora.api.post('/users', data: {'name': 'Jane'});
```

Feature code should not call Dio directly from controllers. Prefer:

```text
Controller -> GetxService -> Repository -> RemoteDataSource -> Velora.api
```

For mock API testing, bind a mock remote data source that implements the same data-source contract. The starter Users module does this with `MockUsersRemoteDataSource`, so screens and services exercise the same repository flow without network calls.
