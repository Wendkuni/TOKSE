import { AlertTriangle, CheckCircle, Info, XCircle } from 'lucide-react';
import { useEffect } from 'react';

export const ConfirmDialog = ({ isOpen, onClose, onConfirm, title, message, type = 'warning' }) => {
  useEffect(() => {
    const handleEscape = (e) => {
      if (e.key === 'Escape') onClose();
    };
    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      return () => document.removeEventListener('keydown', handleEscape);
    }
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const icons = {
    warning: <AlertTriangle className="w-12 h-12 text-orange-500" />,
    danger: <XCircle className="w-12 h-12 text-red-500" />,
    info: <Info className="w-12 h-12 text-blue-500" />,
    success: <CheckCircle className="w-12 h-12 text-green-500" />,
  };

  const buttonColors = {
    warning: 'bg-orange-600 hover:bg-orange-700',
    danger: 'bg-red-600 hover:bg-red-700',
    info: 'bg-blue-600 hover:bg-blue-700',
    success: 'bg-green-600 hover:bg-green-700',
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[100]">
      <div className="bg-white rounded-xl max-w-md w-full mx-4 shadow-2xl animate-scale-in">
        <div className="p-6 text-center">
          <div className="flex justify-center mb-4">
            {icons[type]}
          </div>
          <h3 className="text-xl font-bold text-gray-900 mb-2">{title}</h3>
          <p className="text-gray-600 mb-6">{message}</p>
          <div className="flex gap-3">
            <button
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-medium"
            >
              Annuler
            </button>
            <button
              onClick={() => {
                onConfirm();
                onClose();
              }}
              className={`flex-1 px-4 py-2 text-white rounded-lg transition-colors font-medium ${buttonColors[type]}`}
            >
              Confirmer
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export const AlertDialog = ({ isOpen, onClose, title, message, type = 'info' }) => {
  useEffect(() => {
    const handleEscape = (e) => {
      if (e.key === 'Escape') onClose();
    };
    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      return () => document.removeEventListener('keydown', handleEscape);
    }
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const icons = {
    error: <XCircle className="w-12 h-12 text-red-500" />,
    success: <CheckCircle className="w-12 h-12 text-green-500" />,
    info: <Info className="w-12 h-12 text-blue-500" />,
    warning: <AlertTriangle className="w-12 h-12 text-orange-500" />,
  };

  const buttonColors = {
    error: 'bg-red-600 hover:bg-red-700',
    success: 'bg-green-600 hover:bg-green-700',
    info: 'bg-blue-600 hover:bg-blue-700',
    warning: 'bg-orange-600 hover:bg-orange-700',
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[100]">
      <div className="bg-white rounded-xl max-w-md w-full mx-4 shadow-2xl animate-scale-in">
        <div className="p-6 text-center">
          <div className="flex justify-center mb-4">
            {icons[type]}
          </div>
          <h3 className="text-xl font-bold text-gray-900 mb-2">{title}</h3>
          <p className="text-gray-600 mb-6">{message}</p>
          <button
            onClick={onClose}
            className={`w-full px-4 py-2 text-white rounded-lg transition-colors font-medium ${buttonColors[type]}`}
          >
            OK
          </button>
        </div>
      </div>
    </div>
  );
};
