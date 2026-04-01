/**
 * Dropzone Component
 * 
 * Drag and drop area for image uploads.
 * Supports single and multiple file selection.
 */

import { useState, useRef, useCallback } from 'react'

interface DropzoneProps {
  onFilesSelected: (files: File[]) => void
  isProcessing: boolean
  multiple?: boolean
}

export function Dropzone({ onFilesSelected, isProcessing, multiple = false }: DropzoneProps) {
  const [isDragging, setIsDragging] = useState(false)
  const [previewImages, setPreviewImages] = useState<string[]>([])
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFiles = useCallback((files: FileList | null) => {
    if (!files) return
    
    const validFiles: File[] = []
    const imageUrls: string[] = []
    
    Array.from(files).forEach(file => {
      if (file.type.startsWith('image/')) {
        validFiles.push(file)
        imageUrls.push(URL.createObjectURL(file))
      }
    })
    
    if (validFiles.length > 0) {
      onFilesSelected(validFiles)
      setPreviewImages(imageUrls)
    }
  }, [onFilesSelected])

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(true)
  }

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(false)
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(false)
    handleFiles(e.dataTransfer.files)
  }

  const handleClick = () => {
    fileInputRef.current?.click()
  }

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    handleFiles(e.target.files)
    // Reset input so same file can be selected again
    e.target.value = ''
  }

  return (
    <div
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      onClick={handleClick}
      className={`
        dropzone relative min-h-[300px] flex flex-col items-center justify-center
        transition-all duration-200 cursor-pointer
        ${isDragging ? 'border-slag-amber bg-slag-amber/5' : ''}
        ${isProcessing ? 'opacity-50 cursor-not-allowed' : ''}
      `}
    >
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        multiple={multiple}
        onChange={handleFileChange}
        className="hidden"
        disabled={isProcessing}
      />

      {/* Preview images or upload prompt */}
      {previewImages.length > 0 ? (
        <div className="flex flex-wrap gap-4 justify-center">
          {previewImages.map((url, idx) => (
            <div key={idx} className="relative group">
              <img
                src={url}
                alt={`Preview ${idx + 1}`}
                className="max-w-[200px] max-h-[200px] rounded-lg object-cover"
              />
              <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg flex items-center justify-center">
                <span className="text-sm font-mono text-slag-amber">
                  {multiple ? `${idx + 1}` : 'Ready'}
                </span>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <>
          {/* Upload icon */}
          <div className="mb-4">
            <svg className="w-16 h-16 text-forge-gray" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>
          
          {/* Upload text */}
          <div className="text-center">
            <p className="text-lg text-forge-light mb-2">
              {isProcessing ? 'Slagging...' : 'Drop images here'}
            </p>
            <p className="text-sm text-forge-gray">
              {isProcessing 
                ? 'The forge is working its magic'
                : multiple 
                  ? 'or click to select multiple images'
                  : 'or click to select an image'
              }
            </p>
          </div>

          {/* Supported formats */}
          <div className="mt-4 flex gap-2 text-xs text-forge-gray font-mono">
            <span>PNG</span>
            <span>•</span>
            <span>JPEG</span>
            <span>•</span>
            <span>WebP</span>
            <span>•</span>
            <span>BMP</span>
          </div>
        </>
      )}

      {/* Slagging animation overlay */}
      {isProcessing && (
        <div className="absolute inset-0 bg-forge-black/80 flex items-center justify-center rounded-lg">
          <div className="text-center">
            <div className="w-12 h-12 mx-auto mb-4 border-4 border-slag-amber/30 border-t-slag-amber rounded-full animate-spin" />
            <p className="text-slag-amber font-title tracking-wider">
              SLAGGING...
            </p>
            <p className="text-xs text-forge-light opacity-50 mt-2 font-mono">
              The slag burns away, the gold remains
            </p>
          </div>
        </div>
      )}
    </div>
  )
}
