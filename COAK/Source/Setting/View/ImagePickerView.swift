//
//  ImagePickerView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/14/25.
//

// ImagePickerView.swift - 카메라 사용 가능 여부 체크 포함

import SwiftUI
import UIKit

struct ImagePickerView: UIViewControllerRepresentable {
    enum SourceType {
        case camera, photoLibrary

        var uiImagePickerSource: UIImagePickerController.SourceType {
            switch self {
            case .camera: return .camera
            case .photoLibrary: return .photoLibrary
            }
        }
    }

    var sourceType: SourceType
    var onImagePicked: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator

        let available = UIImagePickerController.isSourceTypeAvailable(sourceType.uiImagePickerSource)
        picker.sourceType = available ? sourceType.uiImagePickerSource : .photoLibrary

        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            parent.onImagePicked(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImagePicked(nil)
            picker.dismiss(animated: true)
        }
    }
}
