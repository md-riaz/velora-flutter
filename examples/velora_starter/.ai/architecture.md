# Architecture

View -> Controller -> GetxService -> Repository -> DataSource -> Velora core.

Controllers only own UI state. Shared session/business state lives in GetxService.
