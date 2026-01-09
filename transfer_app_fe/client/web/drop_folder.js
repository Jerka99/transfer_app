window.handleFolderDrop = (callbackId) => {
  window.__isFolderDrop = false;

  const getFile = (entry) => {
    return new Promise((resolve, reject) => {
      entry.file(resolve, reject);
    });
  };

  const traverseFileTree = async (entry, path = '') => {
    if (entry.isFile) {
      try {
        const file = await getFile(entry);
        const reader = new FileReader();
        reader.onload = () => {
          const array = new Uint8Array(reader.result);
          if (window.__isFolderDrop) {
            window[callbackId](path + file.name, Array.from(array));
          }
        };
        reader.readAsArrayBuffer(file);
      } catch (e) {
        console.error('File read error', e);
      }
    } else if (entry.isDirectory) {
      const dirReader = entry.createReader();
      const readEntries = () => {
        dirReader.readEntries(async (entries) => {
          if (!entries.length) return;
          for (const e of entries) {
            await traverseFileTree(e, path + entry.name + '/');
          }
          readEntries();
        });
      };
      readEntries();
    }
  };

  document.addEventListener('drop', async (event) => {
    event.preventDefault();
    event.stopPropagation();

    const items = event.dataTransfer.items;
    if (!items) return;

    // Only mark folder drop if at least one folder is present
    window.__isFolderDrop = Array.from(items).some(
      (item) => item.webkitGetAsEntry()?.isDirectory
    );

    if (!window.__isFolderDrop) return; // Ignore single files

    for (let i = 0; i < items.length; i++) {
      const entry = items[i].webkitGetAsEntry();
      if (entry) await traverseFileTree(entry);
    }

    // Reset flag after short delay
    setTimeout(() => (window.__isFolderDrop = false), 100);
  });

  document.addEventListener('dragover', (event) => event.preventDefault());
};
