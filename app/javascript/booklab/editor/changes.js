// @flow
// copy from rich-md-editor changes.js
import { Change } from "slate";
import { Editor } from "slate-react";
import EditList from "slate-edit-list";

const { changes } = EditList({
  types: ["ordered-list", "bulleted-list", "todo-list"],
  typeItem: "list-item",
  typeDefault: "paragraph",
});
let uploadCount = 0;

export function splitAndInsertBlock(change, options) {
  const { type, wrapper } = options;
  const parent = change.value.document.getParent(change.value.startBlock.key);

  // lists get some special treatment
  if (parent && parent.type === "list-item") {
    change
      .collapseToStart()
      .call(changes.splitListItem)
      .collapseToEndOfPreviousBlock()
      .call(changes.unwrapList);
  }

  if (wrapper) change.collapseToStartOfNextBlock();

  // this is a hack as insertBlock with normalize: false does not appear to work
  change.insertBlock("paragraph").setBlocks(type, { normalize: false });

  if (wrapper) change.wrapBlock(wrapper);
  return change;
}

export async function insertImageFile(change, file, editor) {
  const { uploadImage, onImageUploadStart, onImageUploadStop } = editor.props;

  if (!uploadImage) {
    console.warn(
      "uploadImage callback must be defined to handle image uploads."
    );
  }

  if (onImageUploadStart) onImageUploadStart();
  try {
    // load the file as a data URL
    const id = `rme-upload-${++uploadCount}`;
    const alt = "";
    const placeholderSrc = URL.createObjectURL(file);
    const node = {
      type: "image",
      isVoid: true,
      data: { src: placeholderSrc, id, alt, loading: true },
    };

    // insert / replace into document as uploading placeholder replacing
    // empty paragraphs if available.
    if (
      !change.value.startBlock.text &&
      change.value.startBlock.type === "paragraph"
    ) {
      change.setBlocks(node);
    } else {
      change.insertBlock(node);
    }

    change.insertBlock("paragraph");

    let props;

    try {
      // now we have a placeholder, start the image upload. This could be very fast
      // or take multiple seconds. The user can further edit the content during this time.
      const src = await uploadImage(file);
      if (!src) {
        throw new Error("No image url returned from uploadImage callback");
      }

      props = {
        data: { src, alt, loading: false },
      };
    } catch (error) {
      if (editor.props.onShowToast) {
        editor.props.onShowToast(
          "Sorry, an error occurred uploading the image"
        );
      }
    }

    const placeholder = editor.value.document.findDescendant(
      node => node.data && node.data.get("id") === id
    );

    // the user may have removed the placeholder while the image was uploaded. In this
    // case we can quietly prevent updating the image.
    if (!placeholder) return;

    // if there was an error during upload, remove the placeholder image
    if (!props) {
      editor.change(change => {
        change.removeNodeByKey(placeholder.key);
      });
    } else {
      editor.change(change => {
        change.setNodeByKey(placeholder.key, props);
      });
    }
  } catch (err) {
    throw err;
  } finally {
    if (onImageUploadStop) onImageUploadStop();
  }
}


export async function insertFile(change, file, editor) {
  const { uploadFile, onFileUploadStart, onFileUploadStop } = editor.props;

  if (!uploadFile) {
    console.warn(
      "uploadFile callback must be defined to handle file uploads."
    );
  }

  if (onFileUploadStart) onFileUploadStart();
  try {
    // load the file as a data URL
    const id = `rme-upload-file-${++uploadCount}`;
    const alt = "";
    const placeholderHref = URL.createObjectURL(file);
    const node = {
      type: "file",
      isVoid: true,
      data: { href: placeholderHref, filename: file.name, size: file.size, id },
    };

    // insert / replace into document as uploading placeholder replacing
    // empty paragraphs if available.
    if (
      !change.value.startBlock.text &&
      change.value.startBlock.type === "paragraph"
    ) {
      change.setBlocks(node);
    } else {
      change.insertBlock(node);
    }

    let props;

    try {
      // now we have a placeholder, start the image upload. This could be very fast
      // or take multiple seconds. The user can further edit the content during this time.
      const href = await uploadFile(file);
      if (!href) {
        throw new Error("No file URL returned from uploadFile callback");
      }

      props = {
        data: { href, filename: file.name, size: file.size },
      };
    } catch (error) {
      if (editor.props.onShowToast) {
        editor.props.onShowToast(
          "Sorry, an error occurred uploading the file"
        );
      }
    }

    const placeholder = editor.value.document.findDescendant(
      node => node.data && node.data.get("id") === id
    );
    // the user may have removed the placeholder while the image was uploaded. In this
    // case we can quietly prevent updating the image.
    if (!placeholder) return;

    // if there was an error during upload, remove the placeholder image
    if (!props) {
      editor.change(change => {
        change.removeNodeByKey(placeholder.key);
      });
    } else {
      editor.change(change => {
        change.setNodeByKey(placeholder.key, props);
      });
    }
  } catch (err) {
    throw err;
  } finally {
    if (onFileUploadStop) onFileUploadStop();
  }
}