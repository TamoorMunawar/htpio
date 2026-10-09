# Handoffs

- Lead -> Team Lead (user): publishing to pub.dev needs the owner's credentials: run `flutter pub publish` from the merged main branch.
- Lead review notes (merged): fixed duplicate middleware `onError` on retries; download manager no longer closes injected clients; interceptor responses re-typed to caller `T`.
- Known limitation (accepted): a log interceptor added *after* RetryInterceptor logs each attempt's error once per nesting level.
